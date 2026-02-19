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

    private let logger = Logger(subsystem: "PLP", category: "Server")
    private var state: OpaquePointer?  // Synchronized on main.

    private var callback: statusCallback_t?

    public func start() {

        // Set up the callback.
        let context = Unmanaged.passRetained(self).toOpaque()
        callback = { context, status in
            guard let context else {
                return
            }
            let ncp = Unmanaged<NCP>.fromOpaque(context).takeUnretainedValue()
            // We dispatch async here to ensure we can't deadlock against `stop` calls on the main queue.
            DispatchQueue.main.async {
                let isConnected = status == 1 ? true : false
                ncp.delegate?.ncp(ncp, didChangeConnectionState: isConnected)
            }
        }

        logger.notice("Starting NCP for device '\(self.device.path)' baud rate \(self.device.baudRate)...")
        state = ncp_init()
        ncp_start(port, device.baudRate, "127.0.0.1", device.path, 0x0000, callback, context, state)
    }

    public init(device: DeviceConfiguration, port: Int32) {
        self.device = device
        self.port = port
    }

    public func stop() {
        guard let state else {
            return
        }
        ncp_stop(state)
    }

}
