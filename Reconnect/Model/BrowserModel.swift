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

@Observable
class BrowserModel {

    enum State {
        case loading
        case ready([FileServer.DirectoryEntry])
        case error(Error)
    }

    // TODO: Surface errors here.

    let fileServer = FileServer(host: "127.0.0.1", port: 7501)
    var history: [String] = []
    var path: String?
    var state: State = .loading
    var selection = Set<FileServer.DirectoryEntry.ID>()

    init() {
        guard fileServer.connect() else {
            state = .error(ReconnectError.general)
            return
        }
        _ = fileServer.devlist()
    }

    func load(path: String, skipHistory: Bool = false) {
        if !skipHistory {
            self.history.append(path)
        }
        self.path = path // TODO: This should be in the view state.
        state = .loading
        do {
            let files = try fileServer.dir(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            state = .ready(files)
        } catch {
            state = .error(error)
        }
    }

    // TODO: Make this a string function?
    func parent() {
        guard let path else {
            return
        }
        var components = path.components(separatedBy: "\\")
        components.removeLast()
        guard components.count > 1 else {
            return
        }
        components.removeLast()
        self.load(path: components.joined(separator: "\\") + "\\")
    }

    // TODO: HIstory shoudl be a struct.
    func back() {
        guard history.count > 1 else {
            return
        }
        history.removeLast()
        guard let path = history.last else {
            return
        }
        load(path: path, skipHistory: false)
    }

}
