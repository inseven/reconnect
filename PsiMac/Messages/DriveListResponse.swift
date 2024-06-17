// PsiMac -- Psion connectivity for macOS
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

import DataStream

struct DriveListResponse: Packable {

    let operationID: UInt16
    let statusCode: UInt32
    let drives: [String]

    init(from stream: DataReadStream) throws {
        let id: UInt16 = try stream.readLE()
        assert(id == 0x11)
        self.operationID = try stream.readLE()
        assert(self.operationID == 0x02)
        self.statusCode = try stream.readLE()
        let drives =  ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        var result = [String]()
        for drive in drives {
            let status: UInt8 = try stream.read()
            print("Testing \(drive)...")
            if status > 0 {
                print(drive)
            }
            result.append(drive)
        }
        self.drives = result
    }

}
