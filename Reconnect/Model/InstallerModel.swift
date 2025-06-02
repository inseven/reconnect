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

    // ContinueQuery / InstallQuery / BeginQuery? InstallPhaseQuery?
    struct DriveQuery: Identifiable {

        let id = UUID()
        let installer: SisFile
        let defaultLanguage: String
        let drives: [FileServer.DriveInfo]

        private let completion: (SisInstallBeginResult) -> Void

        init(installer: SisFile,
             drives: [FileServer.DriveInfo],
             defaultLanguage: String,
             completion: @escaping (SisInstallBeginResult) -> Void) {
            self.installer = installer
            self.drives = drives
            self.defaultLanguage = defaultLanguage
            self.completion = completion
        }

        func resume(_ result: SisInstallBeginResult) {
            completion(result)
        }

    }

    struct TextQuery: Identifiable {

        let id = UUID()
        let installer: SisFile
        let text: String
        let type: InstallerQueryType
        private let completion: (Bool) -> Void

        init(installer: SisFile, text: String, type: InstallerQueryType, completion: @escaping (Bool) -> Void) {
            self.installer = installer
            self.text = text
            self.type = type
            self.completion = completion
        }

        func `continue`(_ continue: Bool) {
            completion(`continue`)
        }

    }

    enum Page {
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

    @MainActor var details: Details?
    @MainActor var page: Page = .loading
    @MainActor var query: Query?

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

    func sisInstallBegin(sis: SisFile, driveRequired: Bool) -> OpoLua.SisInstallBeginResult {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Installing '\(sis.name)'...")

        do {
            let drives = try fileServer.drivesSync().filter { driveInfo in
                driveInfo.mediaType != .rom
            }
            let sem = DispatchSemaphore(value: 0)
            let defaultLanguage = try! Locale.selectLanguage(sis.languages)
            var result: SisInstallBeginResult = .userCancelled
            DispatchQueue.main.sync {
                let query = DriveQuery(installer: sis, drives: drives, defaultLanguage: defaultLanguage) { selection in
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
            return result
        } catch {
            return .epocError(Int(error.rawValue))
        }
    }

    func sisInstallQuery(sis: SisFile, text: String, type: InstallerQueryType) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let sem = DispatchSemaphore(value: 0)
        var result: Bool = false
        DispatchQueue.main.sync {
            let query = TextQuery(installer: sis, text: text, type: type) { response in
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

    func sisInstallRollback(sis: SisFile) -> Bool {
        print("Rolling back...")
        return true
    }

    func sisInstallComplete(sis: SisFile) {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Install phase complete .")
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
