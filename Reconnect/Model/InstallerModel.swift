// Reconnect -- Psion connectivity for macOS
 //
 // Copyright (C) 2024 Jason Morley
 //
 // This program is free software; you can redistribute it and/or modify
 // it under the terms of the GNU General Public License as published by
 // the Free Software Foundation; either version 2 of the License, or
 // (at your option) any later version.
 //
 // This program is distributed in the hope that it will be useful,
 // but WITHOUT ANY WARRANTY; without even the implied warranty of
 // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 // GNU General Public License for more details.
 //
 // You should have received a copy of the GNU General Public License
 // along with this program; if not, write to the Free Software
 // Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

import SwiftUI

import Interact
import OpoLua

import ReconnectCore

@Observable
class InstallerModel: Runnable {

    struct Details: Equatable {
        let name: String
        let version: String
    }

    struct LanguageQuery {

        let languages: [String]
        private let completion: (Result<String, SisInstallError>) -> Void

        init(languages: [String], completion: @escaping (Result<String, SisInstallError>) -> Void) {
            self.languages = languages
            self.completion = completion
        }

        func resume(_ result: Result<String, SisInstallError>) {
            completion(result)
        }
    }

    struct DriveQuery: Identifiable {

        let id = UUID()
        let installer: SisFile
        let drives: [FileServer.DriveInfo]
        let initialSelection: String

        private let completion: (Result<String, Error>) -> Void

        init(installer: SisFile, drives: [FileServer.DriveInfo],
             initialSelection: String,
             completion: @escaping (Result<String, Error>) -> Void) {
            self.installer = installer
            self.drives = drives
            self.initialSelection = initialSelection
            self.completion = completion
        }

        func resume(_ result: Result<String, Error>) {
            completion(result)
        }

    }

    struct TextQuery: Identifiable {

        let id = UUID()
        let text: String
        let type: InstallerQueryType
        private let completion: (Bool) -> Void

        init(text: String, type: InstallerQueryType, completion: @escaping (Bool) -> Void) {
            self.text = text
            self.type = type
            self.completion = completion
        }

        func `continue`(_ continue: Bool) {
            completion(`continue`)
        }

    }

    enum PageType {
        case loading
        case ready
        case copy(String, Float)
        case error(Error)
        case complete
    }

    enum Query: Identifiable {

        var id: UUID {
            switch self {
            case .drive(let driveQuery):
                return driveQuery.id
            case .text(let textQuery):
                return textQuery.id
            }
        }

        case drive(DriveQuery)
        case text(TextQuery)
    }

    private let fileServer = FileServer()

    let url: URL
    private var defaultDrive: String = "C"  // Accessed only from the PsiLuaEnv thread.

    @MainActor var details: Details?
    @MainActor var page: PageType = .loading
    @MainActor var query: Query?
    @MainActor var installers: [SisFile] = []

    init(url: URL) {
        self.url = url
    }

    func start() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let interpreter = PsiLuaEnv()
                let info = interpreter.getFileInfo(path: self.url.path)
                guard case let .sis(sis) = info else {
                    return
                }
                let name = try Locale.localize(sis.name)
                DispatchQueue.main.async {
                    self.details = Details(name: name.text, version: sis.version)
                    self.page = .ready
                    self.install()
                }
            } catch {
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }

    func stop() {

    }

    func install() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let interpreter = PsiLuaEnv()
                try interpreter.installSisFile(path: self.url.path, handler: self)
                DispatchQueue.main.async {
                    self.page = .complete
                }
            } catch {
                print("Failed to install SIS file with error \(error).")
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }

}

extension InstallerModel: SisInstallIoHandler {

    // TODO: Roll this up with the language or drive picker?
    func sisInstallBegin(info: SisFile) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Installing '\(info.name)'...")
        DispatchQueue.main.sync {
            self.installers.append(info)
        }
        return true
    }

    // TODO: See if we can move this into the first step?
    func sisInstallGetLanguage(_ languages: [String]) throws -> String {
        dispatchPrecondition(condition: .notOnQueue(.main))
        return try! Locale.selectLanguage(languages)
    }

    // This is a should install? And it applies to the last sent SisInfo.
    // TODO: Ensure this is always displayed and rename to `sisInstallConfirmation` or something? Ensure this is always first?
    // Does a cancel here match a `false` from `sisInstallBegin`?
    func sisInstallGetDrive() throws -> String {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let drives = try fileServer.drivesSync().filter { driveInfo in
            driveInfo.mediaType != .rom
        }
        let sem = DispatchSemaphore(value: 0)
        let initialSelection = defaultDrive
        var result: Result<String, Error> = .success(initialSelection)
        DispatchQueue.main.sync {
            let query = DriveQuery(installer: installers.last!, drives: drives, initialSelection: initialSelection) { selection in
                result = selection
                sem.signal()
            }
            self.query = .drive(query)
        }
        sem.wait()
        defer {
            DispatchQueue.main.sync {
                self.query = nil
            }
        }
        defaultDrive = try result.get()
        return defaultDrive
    }

    func sisInstallQuery(text: String, type: InstallerQueryType) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let sem = DispatchSemaphore(value: 0)
        var result: Bool = false
        DispatchQueue.main.sync {
            let query = TextQuery(text: text, type: type) { response in
                result = response
                sem.signal()
            }
            self.query = .text(query)
        }
        sem.wait()
        defer {
            DispatchQueue.main.sync {
                self.query = nil
            }
        }
        return result
    }

    func sisInstallRollback() -> Bool {
        print("Rolling back...")
        return true
    }

    func sisInstallComplete() {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Install phase complete .")
        DispatchQueue.main.sync {
            _ = self.installers.removeLast()
        }
    }

    func fsop(_ operation: Fs.Operation) -> Fs.Result {
        dispatchPrecondition(condition: .notOnQueue(.main))
        do {
            switch operation.type {
            case .delete:
                return .err(.notReady)
            case .mkdir:
                try fileServer.mkdirSync(path: operation.path)
                return .success
            case .rmdir:
                return .err(.notReady)
            case .write(let data):
                DispatchQueue.main.sync {
                    self.page = .copy(operation.path, 0.0)
                }
                let temporaryURL = FileManager.default.temporaryURL()
                defer {
                    do {
                        try FileManager.default.removeItem(at: temporaryURL)
                    } catch {
                        print("Failed to clean up temporary file with error '\(error)'.")
                    }
                }
                try data.write(to: temporaryURL)
                try fileServer.copyFileSync(fromLocalPath: temporaryURL.path, toRemotePath: operation.path) { progress, size in
                    DispatchQueue.main.sync {
                        self.page = .copy(operation.path, Float(progress) / Float(size))
                    }
                    return .continue
                }
                return .success
            case .stat:
                let attributes = try fileServer.getExtendedAttributesSync(path: operation.path)
                return .stat(Fs.Stat(size: UInt64(attributes.size), lastModified: Date.now, isDirectory: false))
            default:
                print("Unsupported operation '\(operation.type)' '\(operation.path)'")
                return .err(.notReady)
            }

        } catch PLPToolsError.inUse {
            return .err(.inUse)
        } catch PLPToolsError.noSuchFile,
                PLPToolsError.noSuchDevice,
                PLPToolsError.noSuchRecord,
                PLPToolsError.noSuchDirectory {
            return .err(.notFound)
        } catch PLPToolsError.fileAlreadyExists {
            return .err(.alreadyExists)
        } catch PLPToolsError.notReady {
            return .err(.notReady)
        } catch {
            print("Encountered unmapped internal plptools error during install '\(error)'.")
            return .err(.general)
        }
    }

}
