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

extension FileServer {

    /**
     Get the last backup identifier if and only if one is set and the identifier is still considered valid (the file
     still has the archive bit set).
     */
    public func lastBackupIdentifier() throws -> UUID? {
        let lastBackupIdentifierPath: String = ((try protocolVersion()) == 3
                                                ? .epoc16LastBackupIdentifierPath
                                                : .epoc32LastBackupIdentifierPath)

        // Check to see if there's a last backup identifier and that it has the archive bit set (see note below).
        guard try exists(path: lastBackupIdentifierPath),
              (try getAttributes(path: lastBackupIdentifierPath).contains(.archive)),
              let uuidString = String(data: try readFile(path: lastBackupIdentifierPath), encoding: .ascii)
        else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

}
