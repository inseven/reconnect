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

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Connect") {

                do {

                    let socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
                    try socket.setBlocking(mode: true)
                    try socket.connect(to: "127.0.0.1", port: 7501)

//                    try socket.send("NCP$INFO")
//                    try socket.process()

//                    let rpcs = try RPCS(socket: socket)
//                    print(try rpcs.getOwnerInfo())
//                    print(try rpcs.getMachineInfo())
//                    print(try rpcs.getMachineType())

                    let fileServer = try RFSV(socket: socket)
                    print(try fileServer.getDriveList())

                    print("Done.")

                } catch {
                    print("Failed to connect with error \(error).")
                }

            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
