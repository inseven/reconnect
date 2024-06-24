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

    struct FileAttributes: OptionSet {

        let rawValue: UInt32

        static let readOnly = FileAttributes(rawValue: 0x0001)
        static let hidden = FileAttributes(rawValue: 0x0002)
        static let system = FileAttributes(rawValue: 0x0004)
        static let directory = FileAttributes(rawValue: 0x0008)
        static let archive = FileAttributes(rawValue: 0x0010)
        static let volume = FileAttributes(rawValue: 0x0020)

        // EPOC
        static let normal = FileAttributes(rawValue: 0x0040)
        static let temporary = FileAttributes(rawValue: 0x0080)
        static let compressed = FileAttributes(rawValue: 0x0100)

        // SIBO
        static let read = FileAttributes(rawValue: 0x0200)
        static let exec = FileAttributes(rawValue: 0x0400)
        static let stream = FileAttributes(rawValue: 0x0800)
        static let text = FileAttributes(rawValue: 0x1000)

    }

    struct DirectoryEntry: Identifiable, Hashable {

        var id: String {
            return path
        }

        let path: String
        let name: String
        let size: UInt32
        let attributes: FileAttributes

        func hash(into hasher: inout Hasher) {
            hasher.combine(path)
        }
        
    }

    let host: String
    let port: Int32

    var client = RFSVClient()

    init(host: String, port: Int32) {
        self.host = host
        self.port = port
    }

    func connect() -> Bool {
        return client.connect(host, port)
    }

    func dir(path: String) throws -> [DirectoryEntry] {
        var details = PlpDir()
        client.dir(path, &details)

        var entries: [DirectoryEntry] = []

        for i in 0..<details.count {
            var entry: PlpDirent = details[i]
            let name = String(cString: plpdirent_get_name(&entry))
            let attributes = FileAttributes(rawValue: entry.getAttr())

            let filePath: String
            switch attributes.contains(.directory) {
            case true:
                filePath = path + name + "\\"
            case false:
                filePath = path + name
            }

            entries.append(DirectoryEntry(path: filePath,
                                          name: name,
                                          size: entry.getSize(),
                                          attributes: attributes))
        }
        return entries
    }

    func devlist() -> [String] {
        var devbits: UInt32 = 0
        client.devlist(&devbits)
        print("devbits = \(devbits)")
        return []
    }

}
