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

// TODO: Shared file server?
@Observable
class ProgramManagerModel: Runnable {

    struct ProgramDetails {
        let path: String
        let sis: Sis.File
    }

    enum State {
        case checkingInstalledPackages(Double)
        case ready
        case error(Error)
    }

    var state: State = .checkingInstalledPackages(0.0)
    var installedPrograms: [ProgramDetails] = []

    let syncQueue = DispatchQueue(label: "ProgramManagerModel.syncQueue")
    let fileServer = FileServer()

    func start() {
        syncQueue.async {
            do {
                // Get the installed stubs.
                let stubs = try self.fileServer.getStubs { progress in
                    DispatchQueue.main.sync {
                        print(progress)
                        self.state = .checkingInstalledPackages(progress.fractionCompleted)
                    }
                    return .continue
                }
                // Parse them to determine the program names and versions.
                let interpreter = PsiLuaEnv()
                let installedPrograms = try stubs.map { stub in
                    return ProgramDetails(path: stub.path, sis: try interpreter.loadSisFile(data: stub.contents))
                }
                // Update the model with the new state.
                DispatchQueue.main.sync {
                    self.installedPrograms = installedPrograms
                    self.state = .ready
                }
            } catch {
                DispatchQueue.main.sync {
                    self.state = .error(error)
                }
            }
        }
    }

    func stop() {

    }

}
