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

    struct Query {

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
        case initial
        case query(Query)
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
        return languages[0]
    }

    func sisInstallQuery(text: String, type: OpoLua.InstallerQueryType) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let sem = DispatchSemaphore(value: 0)
        var result: Bool = false
        DispatchQueue.main.sync {
            let query = Query(text: text, type: type) { response in
                result = response
                sem.signal()
            }
            self.page = .query(query)
        }
        sem.wait()
        return result
    }

    // TODO: Extension on the file server?
    func fsop(_ operation: Fs.Operation) -> Fs.Result {
        dispatchPrecondition(condition: .notOnQueue(.main))
        do {
            print("\(operation.type) '\(operation.path)'")
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
                // TODO: Move into `FileServer`. Is this even necessary? Does it make a difference?
                DispatchQueue.main.sync {
                    self.page = .copy(operation.path, 1.0)
                }
                return .err(.none)
            case .read:
                return .err(.notReady)
            case .dir:
                return .err(.notReady)
            case .rename(_):
                return .err(.notReady)
            case .stat:
                print("stat '\(operation.path)'")
                let attributes = try fileServer.getExtendedAttributesSync(path: operation.path)
                return .stat(Fs.Stat(size: UInt64(attributes.size), lastModified: Date.now, isDirectory: false))
            case .disks:
                return .err(.notReady)
            }

            // TODO: Map these to Fs.Operation errors
//            switch error {
//            case .general:
//            case .badArgument:
//            case .osError:
//            case .notSupported:
//            case .underflow:
//            case .overflow:
//            case .outOfRange:
//            case .divideByZero:
//            case .inUse:
//            case .outOfMemory:
//            case .outOfSegments:
//            case .outOfSemaphores:
//            case .outOfProcesses:
//            case .alreadyOpen:
//            case .notOpen:
//            case .badImage:
//            case .receiveError:
//            case .deviceError:
//            case .noFilesystem:
//            case .notReady:
//            case .noFont:
//            case .tooWide:
//            case .tooMany:
//            case .fileAlreadyExists:
//            case .noSuchFile:
//            case .writeError:
//            case .readError:
//            case .endOfFile:
//            case .readBufferFull:
//            case .invalidFileName:
//            case .accessDenied:
//            case .resourceLocked:
//            case .noSuchDevice:
//            case .noSuchDirectory:
//            case .noSuchRecord:
//            case .fileIsReadOnly:
//            case .invalidIOOperation:
//            case .ioPending:
//            case .invalidVolumeName:
//            case .cancelled:
//            case .noMemoryForControlBlock:
//            case .unitDisconnected:
//            case .alreadyConnected:
//            case .retransmissionThresholdExceeded:
//            case .physicalLinkFailure:
//            case .inactivityTimerExpired:
//            case .serialParityError:
//            case .serialFramingError:
//            case .serialOverrunError:
//            case .modemCannotConnectToRemoteModem:
//            case .remoteModemBusy:
//            case .remoteModemDidNotAnswer:
//            case .numberBlacklistedByTheModem:
//            case .driveNotReady:
//            case .unknownMedia:
//            case .directoryFull:
//            case .writeProtected:
//            case .mediaCorrupt:
//            case .abortedOperation:
//            case .failedToEraseFlashMedia:
//            case .invalidFileForDBFSystem:
//            case .powerFailure:
//            case .tooBig:
//            case .badDescriptor:
//            case .badEntryPoint:
//            case .couldNotDisconnect:
//            case .badDriver:
//            case .operationNotCompleted:
//            case .serverBusy:
//            case .terminated:
//            case .died:
//            case .badHandle:
//            }
        } catch {
            return .err(.notFound)  // TODO: Map errors. General error or unknown would be nice!
        }
    }

}
