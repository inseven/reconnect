// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2025 Jason Morley
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
class ProgramManagerModel: Runnable, @unchecked Sendable {

    struct ProgramDetails: Identifiable, Hashable {

        var id: String {
            return "\(path):\(sis.id)"
        }

        let path: String
        let sis: Sis.File
    }

    enum State {
        case checkingInstalledPackages(Progress)
        case ready
        case error(Error)
    }

    var state: State = .checkingInstalledPackages(Progress())
    var stubs: [Sis.Stub] = []
    var installedPrograms: [ProgramDetails] = []

    let syncQueue = DispatchQueue(label: "ProgramManagerModel.syncQueue")
    let deviceModel: DeviceModel

    var isReady: Bool {
        guard case .ready = state else {
            return false
        }
        return true
    }

    init(deviceModel: DeviceModel) {
        self.deviceModel = deviceModel
    }

    func remove(uid: UInt32) {
        syncQueue.async { [stubs] in
            do {
                let interpreter = PsiLuaEnv()
                try interpreter.uninstallSisFile(stubs: stubs, uid: uid, handler: self)
            } catch {
                DispatchQueue.main.sync {
                    self.state = .error(error)
                }
            }
            self.syncQueue_reload()
        }
    }

    private func syncQueue_reload() {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        do {
            guard let installDirectory = deviceModel.installDirectory else {
                print("Unable to determine device install directory.")
                return
            }

            // Get the installed stubs.
            let stubs = try deviceModel.fileServer.getStubs(installDirectory: installDirectory) { progress in
                DispatchQueue.main.sync {
                    self.state = .checkingInstalledPackages(progress)
                }
                return .continue
            }
            // Parse them to determine the program names and versions.
            let interpreter = PsiLuaEnv()
            let installedPrograms = try stubs.map { stub in
                return ProgramDetails(path: stub.path, sis: try interpreter.loadSisFile(data: stub.contents))
            }.sorted {
                $0.sis.localizedDisplayName.localizedCaseInsensitiveCompare($1.sis.localizedDisplayName) == .orderedAscending
            }

            // Update the model with the new state.
            DispatchQueue.main.sync {
                self.stubs = stubs
                self.installedPrograms = installedPrograms
                self.state = .ready
            }
        } catch {
            DispatchQueue.main.sync {
                self.state = .error(error)
            }
        }
    }

    @MainActor
    func start() {
        syncQueue.async {
            self.syncQueue_reload()
        }
    }

    func stop() {

    }

    func reload() {
        dispatchPrecondition(condition: .onQueue(.main))
        syncQueue.async {
            self.syncQueue_reload()
        }
    }

}

extension ProgramManagerModel: OpoLua.FileSystemIoHandler {

    func fsop(_ operation: Fs.Operation) -> Fs.Result {
        dispatchPrecondition(condition: .notOnQueue(.main))
        return deviceModel.fileServer.fsop(operation) { progress in
            DispatchQueue.main.sync {
                print("\(operation): \(progress)")
            }
        }
    }

}
