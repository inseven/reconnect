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

struct Backup: Equatable, Hashable {
    let manifest: BackupManifest
    let url: URL
}

extension Backup {

    /**
     Return the URL of a file in the backup.

     @param path The Psion-format path of the file to lookup; must be absolute

     @return File URL of the file if it exists in the backup; nil otherwise
     */
    func url(forPath path: String) -> URL? {

        // Construct the URL.
        let components = path.windowsPathComponents
        guard let drive = components.first else {
            return nil
        }
        let driveLetter = String(drive[..<drive.index(drive.startIndex, offsetBy: 1)])
        let fileURL = url
            .appendingPathComponent(driveLetter)
            .appendingPathComponents(Array(components[1...]))

        // Ensure the file exists.
        guard FileManager.default.fileExists(at: fileURL) else {
            return nil
        }

        return fileURL
    }

}
