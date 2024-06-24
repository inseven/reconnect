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

import Foundation

import ncp
import plpftp

class FileServer {

    struct DirectoryEntry {
        let name: String
        let size: Int
        let attributes: Int
    }

    let host: String
    let port: Int32
    var context = Context()

    init(host: String, port: Int32) {
        self.host = host
        self.port = port
        plp_init(&context)
    }

    // TODO: Free / Disconnect.

    func connect() {
        plp_connect(&context, host, port)
    }

    func dir(path: String) throws -> [DirectoryEntry] {
        guard let result = rfsv_dir(&context, path) else {
            print("Unable to list directory")
            throw ReconnectError.general
        }
        defer {
            directory_list_free(result)
        }
        let buffer = UnsafeBufferPointer(start: result.pointee.entries, count: Int(result.pointee.count))
        return Array(buffer).map {
            DirectoryEntry(name: String(cString: $0.name),
                           size: $0.size,
                           attributes: $0.attr)
        }
    }

}
