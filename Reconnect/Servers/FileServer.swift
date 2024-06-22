//
//  ContentView.swift
//  PsiMac
//
//  Created by Jason Barrie Morley on 13/06/2024.
//

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
