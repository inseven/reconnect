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

@Observable
class Server {

    var isConnected: Bool = false

    func threadEntryPoint() {

        let context = Unmanaged.passRetained(self).toOpaque()
        let callback: statusCallback_t = { context, status in
            guard let context else {
                return
            }
            print("status = \(status)")
            let server = Unmanaged<Server>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.sync {
                server.isConnected = status == 1 ? true : false
            }
        }

        let device = "/dev/tty.usbserial-AL00AYCG"
//        let device = "/dev/tty.usbserial-A91MGK6M"

//        let log: UInt16 = 1 | 2 | 4 | 8 | 18 | 32 | 64
        let log: UInt16 = 0

        ncpd(7501, 115200, "127.0.0.1", device, log, callback, context)
    }

    init() {
        // Create a new thread and start it
        let thread = Thread(block: threadEntryPoint)
        thread.start()
    }

}
