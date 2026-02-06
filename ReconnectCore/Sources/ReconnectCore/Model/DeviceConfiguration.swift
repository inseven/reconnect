// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2026 Jason Morley
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

/**
 * Device-specific configuration.
 *
 * Serialization uses the INI file format with Windows line endings to make it as easy as possible to parse on a Psion.
 */
public struct DeviceConfiguration: Equatable, Hashable, Codable {

    public let id: UUID
    public let name: String

    public init(id: UUID = UUID(), name: String = "My Psion") {
        self.id = id
        self.name = name
    }

    public init(data: Data) throws {
        guard let contents = String(data: data, encoding: .ascii) else {
            throw ReconnectError.configurationDencodeError
        }

        // Separate the lines and trim any unwanted whitespace.
        let lines = contents
            .split(separator: "\r\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var parameters: [String: String] = [:]

        // Iterate over the remaining lines and split out 'key = value' tuples. We require that every non-empty line is
        // a parameter.
        for line in lines {
            let parameter = line
                .split(separator: "=", maxSplits: 2)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parameter.count == 2 else {
                throw ReconnectError.configurationDencodeError
            }
            let key = String(parameter[0]).lowercased()
            let value = String(parameter[1])
            parameters[key] = value
        }

        guard
            let idString = parameters["id"],
            let id = UUID(uuidString: idString),
            let name = parameters["name"]
        else {
            throw ReconnectError.configurationDencodeError
        }

        self.init(id: id, name: name)
    }

    public func data() throws -> Data {
        guard let data = "id = \(id.uuidString)\r\nname = \(name)\r\n".data(using: .ascii) else {
            throw ReconnectError.configurationEncodeError
        }
        return data
    }

}
