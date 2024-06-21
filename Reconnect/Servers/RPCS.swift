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

import Socket
import DataStream

struct RPCS {

    enum Command: UInt8 {
        case queryNCP = 0x00
        case execProg = 0x01
        case queryDrive = 0x02
        case stopProg = 0x03
        case queryProg = 0x04
        case formatOpen = 0x05
        case formatRead = 0x06
        case getUniqueId = 0x07
        case getOwnerInfo = 0x08
        case getMachineType = 0x09
        case getCmdLine = 0x0a
        case fUser = 0x0b
        case getMachineInfo = 0x64
    }

    let socket: Socket

    init(socket: Socket) throws {
        self.socket = socket
        try socket.send("SYS$RPCS")  // TODO: Load server?
        try socket.process()
    }

    private func perform<T: Packable>(command: Command) throws -> T {
        return try T(from: try socket.sendReceive([command.rawValue]))
    }

    func getOwnerInfo() throws -> OwnerInfoResponse {
        return try perform(command: .getOwnerInfo)
    }

    func getMachineInfo() throws -> MachineInfoResponse {
        return try perform(command: .getMachineInfo)
    }

    func getMachineType() throws -> MachineTypeResponse {
        return try perform(command: .getMachineType)
    }

}
