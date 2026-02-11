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

import ReconnectCore

struct BackupManifest: Equatable, Hashable, Codable {

    struct Drive: Equatable, Hashable, Codable, Identifiable {

        var id: String {
            return drive
        }

        let drive: String
        let mediaType: FileServer.MediaType
        let driveAttributes: FileServer.DriveAttributes
        let name: String?
    }

    let device: DeviceConfiguration
    let platform: Platform?
    let date: Date
    let drives: [Drive]

    init(device: DeviceConfiguration, platform: Platform, date: Date, drives: [Drive]) {
        self.device = device
        self.platform = platform
        self.date = date
        self.drives = drives
    }

    init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Self.self, from: data)
    }

    func write(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url, options: .atomic)
    }

}
