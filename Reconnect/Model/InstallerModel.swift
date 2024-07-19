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

@Observable
class InstallerModel {

    @MainActor var error: Error?

    let fileServer = FileServer()
    let interpreter = PsiLuaEnv()

    let url: URL

    init(_ url: URL) {
        self.url = url
    }

    func run() {
        do {
            try interpreter.installSisFile(path: url.path, handler: self)
        } catch {
            print("Failed to install SIS file with error \(error).")
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }

}

extension InstallerModel: SisInstallIoHandler {

    func fsop(_ op: Fs.Operation) -> Fs.Result {
        print(op)
        return .err(.notReady)
    }

}
