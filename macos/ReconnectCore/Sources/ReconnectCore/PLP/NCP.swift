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

import os
import Foundation

import ncp

// Callbacks on main.
public protocol NCPDelegate: NSObject {

    func ncp(_ ncp: NCP, didChangeConnectionState isConnected: Bool)

}

// TODO: NCPSession?
public class NCP {

    public struct DeviceConfiguration: Equatable, Hashable {

        public let path: String
        public let baudRate: Int32

        public init(path: String, baudRate: Int32) {
            self.path = path
            self.baudRate = baudRate
        }

    }

    public weak var delegate: NCPDelegate? = nil

    public let device: DeviceConfiguration
    public let port: Int32

    private let lock = NSLock()
    private let logger = Logger(subsystem: "PLP", category: "Server")

    // Synchronized with lock.
    private var threadID: pthread_t? = nil
    private var isCancelled: Bool = false

    func threadEntryPoint() {

        setup_signal_handlers()

        lock.withLock {
            threadID = pthread_self()
        }

        let context = Unmanaged.passRetained(self).toOpaque()
        let callback: statusCallback_t = { context, status in
            guard let context else {
                return
            }
            let ncp = Unmanaged<NCP>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.sync {
                let isConnected = status == 1 ? true : false
                ncp.delegate?.ncp(ncp, didChangeConnectionState: isConnected)
            }
        }

        while true {
            logger.notice("Starting NCP for device '\(self.device.path)' baud rate \(self.device.baudRate)...")
            ncpd(port, device.baudRate, "127.0.0.1", device.path, 0x0000, callback, context)
            DispatchQueue.main.async {
                self.delegate?.ncp(self, didChangeConnectionState: false)
            }
            logger.notice("NCP session ended.")

            // Check to see if we need to exit.
            let isCancelled: Bool = lock.withLock {
                return self.isCancelled
            }
            if isCancelled {
                logger.notice("NCP thread exiting.")
                return
            }
        }
    }

    public init(device: DeviceConfiguration, port: Int32) {
        self.device = device
        self.port = port

    }

    public func start() {
        let thread = Thread(block: threadEntryPoint)
        thread.start()
    }

    public func stop() {

        // Cancel the thread and get its id.
        let threadID = lock.withLock {
            isCancelled = true
            return self.threadID
        }
        guard let threadID = threadID else {
            return
        }

        // Signal the thread to stop it and then join it to ensure it's stopped.
        pthread_kill(threadID, SIGINT)
        pthread_join(threadID, nil)
    }

}
