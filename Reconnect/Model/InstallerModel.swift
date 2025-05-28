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

import OpoLua

import ReconnectCore

@Observable
class InstallerModel {

    struct LanguageQuery {

        let languages: [String]
        private let completion: (String) -> Void

        init(languages: [String], completion: @escaping (String) -> Void) {
            self.languages = languages
            self.completion = completion
        }

        func `continue`(_ selection: String) {
            completion(selection)
        }
    }

    struct TextQuery {

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
        case initial
        case languageQuery(LanguageQuery)
        case query(TextQuery)
        case copy(String, Float)
        case error(Error)
        case complete
    }

    private let fileServer = FileServer()
    private let interpreter = PsiLuaEnv()

    private let installer: InstallerDocument

    @MainActor var page: PageType = .initial

    init(_ installer: InstallerDocument) {
        self.installer = installer
    }

    func run() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try self.interpreter.installSisFile(data: self.installer.snapshot(contentType: .data), handler: self)
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

    func sisInstallGetLanguage(_ languages: [String]) -> String? {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let sem = DispatchSemaphore(value: 0)
        var language = languages[0]
        DispatchQueue.main.sync {
            let query = LanguageQuery(languages: languages) { selection in
                language = selection
                sem.signal()
            }
            self.page = .languageQuery(query)
        }
        sem.wait()
        return language
    }

    func sisInstallQuery(text: String, type: OpoLua.InstallerQueryType) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let sem = DispatchSemaphore(value: 0)
        var result: Bool = false
        DispatchQueue.main.sync {
            let query = TextQuery(text: text, type: type) { response in
                result = response
                sem.signal()
            }
            self.page = .query(query)
        }
        sem.wait()
        return result
    }

    func fsop(_ operation: Fs.Operation) -> Fs.Result {
        dispatchPrecondition(condition: .notOnQueue(.main))
        do {

            switch operation.type {
            case .delete:
                return .err(.notReady)
            case .mkdir:
                try fileServer.mkdirSync(path: operation.path)
                return .err(.none)
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
                return .err(.none)
            case .stat:
                print("stat '\(operation.path)'")
                let attributes = try fileServer.getExtendedAttributesSync(path: operation.path)
                return .stat(Fs.Stat(size: UInt64(attributes.size), lastModified: Date.now, isDirectory: false))
            default:
                print("Unsupported operation '\(operation.type)' '\(operation.path)'")
                return .err(.notReady)
            }

        } catch FileServerError.inUse {
            return .err(.inUse)
        } catch FileServerError.noSuchFile,
                FileServerError.noSuchDevice,
                FileServerError.noSuchRecord,
                FileServerError.noSuchDirectory {
            return .err(.notFound)
        } catch FileServerError.fileAlreadyExists {
            return .err(.alreadyExists)
        } catch FileServerError.notReady {
            return .err(.notReady)
        } catch {
            // TODO: Introduce a general error that accepts a string.
            return .err(.notReady)
        }
    }

}
