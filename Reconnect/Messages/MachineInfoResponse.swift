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

import Foundation

import DataStream

struct MachineInfoResponse: Packable {

    let statusCode: UInt8
    let machineType: MachineType
    let majorRomVersion: UInt8
    let minorRomVersion: UInt8
    let romBuild: UInt16
    let reserved1: UInt32
    let reserved2: UInt32
    let name: String
    let displayWidth: UInt32
    let displayHeight: UInt32

    init(from stream: DataReadStream) throws {
        self.statusCode = try stream.read()
        self.machineType = MachineType(rawValue: try stream.readLE())!
        self.majorRomVersion = try stream.read()
        self.minorRomVersion = try stream.read()
        self.romBuild = try stream.readLE()
        self.reserved1 = try stream.read()
        self.reserved2 = try stream.read()
        self.name = try stream.read(length: 16)
        self.displayWidth = try stream.readLE()
        self.displayHeight = try stream.readLE()

        stream.seek(offset: 136)
        let ramSize: UInt32 = try stream.readLE()
        print(ramSize)

    }

}
