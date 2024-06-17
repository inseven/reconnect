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

import Socket
import DataStream

struct RFSV {

    enum Commands: UInt16 {
        case getDriveList = 0x13
    }

    let socket: Socket

    init(socket: Socket) throws {
        self.socket = socket
        try socket.send("SYS$RFSV.*")
        try socket.process()
    }

    func getDriveList() throws -> [String] {
        try socket.write([0x00, 0x00, 0x00, 0x04, 0x13, 0x00, 0x02, 0x00])
        let response: DriveListResponse = try socket.response()
        return response.drives
    }

}
