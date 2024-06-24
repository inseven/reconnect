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

    // TODO: Surface errors here.

    let fileServer = FileServer(host: "127.0.0.1", port: 7501)

    var files: [FileServer.DirectoryEntry] = []
    var error: Error? = nil

    init() {
        fileServer.connect()
        do {
            files = try fileServer.dir(path: "C:\\")
        } catch {
            self.error = error
        }
    }

}

extension FileServer.DirectoryEntry: Identifiable {

    var id: String {
        return name
    }

}

struct BrowserView: View {

    @State var model = BrowserModel()

    var body: some View {
        Table(model.files) {
            TableColumn("Name", value: \.name)
            TableColumn("Size") { file in
                Text(String(file.size))
            }
            TableColumn("Attributes") { file in
                Text(String(file.attributes))
            }
        }
    }

}
