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
        do {
            try interpreter.installSisFile(data: installer.snapshot(contentType: .data), handler: self)
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

extension InstallerModel: SisInstallIoHandler {

    func sisInstallQuery(text: String, type: OpoLua.InstallerQueryType) -> Bool {
        let sem = DispatchSemaphore(value: 1)
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

    func fsop(_ op: Fs.Operation) -> Fs.Result {
        print(op)
        return .err(.notReady)
    }

}
