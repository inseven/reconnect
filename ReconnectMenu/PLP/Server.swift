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

import Foundation

import ncp

protocol ServerDelegate: NSObject {

    func server(server: Server, didChangeConnectionState isConnected: Bool)

}

class Server {

    weak var delegate: ServerDelegate? = nil

    var lock = NSLock()
    var threadID: pthread_t? = nil  // Synchronized with lock.
    var devices: [String] = []  // Synchronized with lock.

    func device() -> String {
        print("Getting device...")
        while true {
            let devices = lock.withLock {
                return self.devices
            }
            if let device = devices.first {
                return device
            }
            print("Waiting for devices...")
            sleep(1)
        }
    }

    func threadEntryPoint() {

        setup_signal_handlers()

        // TODO: Maybe this shouldn't be a member?
        lock.withLock {
            threadID = pthread_self()
        }

        let context = Unmanaged.passRetained(self).toOpaque()
        let callback: statusCallback_t = { context, status in
            guard let context else {
                return
            }
            print("status = \(status)")
            let server = Unmanaged<Server>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.sync {
                let isConnected = status == 1 ? true : false
                server.delegate?.server(server: server, didChangeConnectionState: isConnected)
            }
        }

        while true {
            let device = self.device()
            print("Using device \(device)...")
            ncpd(7501, 115200, "127.0.0.1", device, 0x0000, callback, context)
            DispatchQueue.main.async {
                self.delegate?.server(server: self, didChangeConnectionState: false)
            }
            print("ncpd ended")
        }
    }

    init() {
        // Create a new thread and start it
    }

    func start() {
        // TODO: ONLY DO THIS ONCE!
        let thread = Thread(block: threadEntryPoint)
        thread.start()

        // TODO: This should probably block until we're ready??
    }

    func setDevices(_ devices: [String]) {
        // SIGHUP?
        guard let threadID = lock.withLock({
            return self.threadID
        }) else {
            return
        }

        print("Updating serial devices \(devices)")

        let needsRestart = lock.withLock {
            guard self.devices != devices else {
                return false
            }
            self.devices = devices
            return true
        }

        guard needsRestart else {
            print("Serial devices haven't changed; ignoring.")
            return
        }

        print("Restarting ncpd...")
        pthread_kill(threadID, SIGINT)
    }

}
