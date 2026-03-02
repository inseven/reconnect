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

import Foundation
import os

import ReconnectCore

class SessionManager: NSObject {

    public weak var delegate: NCPDelegate? = nil

    private let logger = Logger(subsystem: "reconnectd", category: "SessionManager")
    private let workQueue = DispatchQueue(label: "SessionManager.workQueue", qos: .userInteractive)

    private var sessions: [NCP.DeviceConfiguration: NCP] = [:]  // Synchronized on workQueue.

    override init() {
    }

    func update(_ activeDeviceConfigurations: [NCP.DeviceConfiguration]) {
        workQueue.async { [self] in

            // 1) Stop the ncpd sessions that aren't available any more.
            let removedDeviceConfigurations = sessions.filter { !activeDeviceConfigurations.contains($0.key) }
            for (deviceConfiguration, ncp) in removedDeviceConfigurations {
                logger.notice("Stopping ncpd for \(deviceConfiguration.path) on port \(ncp.port)...")
                ncp.stop()
                logger.notice("Stopped ncpd for \(deviceConfiguration.path) on port \(ncp.port).")
                sessions.removeValue(forKey: deviceConfiguration)
            }

            // 2) Create new ncpd sesisons and start them, allocating the next free TCP port.
            logger.notice("Restarting sessions for \(activeDeviceConfigurations.count) devices.")
            var ports = Set(sessions.map({ $0.value.port }))
            var nextPort: Int32 = 7501
            for deviceConfiguration in activeDeviceConfigurations {
                if sessions[deviceConfiguration] == nil {
                    while ports.contains(nextPort) {
                        nextPort += 1
                    }
                    ports.insert(nextPort)
                    logger.notice("Starting ncpd for \(deviceConfiguration.path) on port \(nextPort)...")
                    let ncp = NCP(device: deviceConfiguration, port: nextPort)
                    ncp.delegate = self
                    sessions[deviceConfiguration] = ncp

                    // While it's pretty grim, but we dispatch blocking back to the main thread to start each ncp
                    // session. This ensures we inherit the correct thread priority when the session is started using
                    // `pthread_create`, without having to change the internal plptools implementation. Thankfully,
                    // this does almost no work except for setting up the thread state and starting it.
                    DispatchQueue.main.sync {
                        ncp.start()
                    }
                }
            }
        }
    }

}

extension SessionManager: NCPDelegate {

    func ncp(_ ncp: ReconnectCore.NCP, didChangeConnectionState isConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        delegate?.ncp(ncp, didChangeConnectionState: isConnected)
    }

}
