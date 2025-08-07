// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2025 Jason Morley
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
import SwiftUI

// Callbacks occur on main.
@MainActor
public protocol DaemonClientDelegate: NSObject {

    func daemonClientDidConnect(_ daemonClient: DaemonClient)
    func daemonClientDidDisconnect(_ daemonClient: DaemonClient)
    func daemonClient(_ daemonClient: DaemonClient, didUpdateDeviceConnectionState isDeviceConnected: Bool)
    func daemonClient(_ daemonClient: DaemonClient, didUpdateSerialDevices serialDevices: [SerialDevice])

}

@Observable
public class DaemonClient {

    // Synchronized on main.
    public weak var delegate: DaemonClientDelegate? = nil

    private let logger = Logger()
    private let workQueue = DispatchQueue(label: "DaemonClient.workQueue")

    // Synchronized on workQueue.
    private var connection: NSXPCConnection!

    // Synchronized on main.
    private var wantsConnection: Bool = false  // Indicates if we should be trying to maintain a daemon connection (are we running?).

    public init() {}

    public func connect() {
        guard !wantsConnection else {
            return
        }
        wantsConnection = true
        workQueue.async { [self] in
            workQueue_connect()
        }
    }

    public func disconnect() {
        guard wantsConnection else {
            return
        }
        wantsConnection = false
        workQueue.sync { [self] in
            workQueue_disconnect()
        }
    }

    private func workQueue_connect() {
        dispatchPrecondition(condition: .onQueue(workQueue))

        let shouldConnect = DispatchQueue.main.sync {
            return wantsConnection
        }

        guard shouldConnect else {
            logger.notice("Disconnect requested; not attempting to reconnect.")
            return
        }

        logger.notice("Connecting...")
        connection = NSXPCConnection(machServiceName: .daemonSericeName,
                                     options: [])
        connection.remoteObjectInterface = .daemonInterface
        connection.exportedInterface = .daemonClientInterface
        connection.exportedObject = self
        connection.interruptionHandler = { [weak self] in
            self?.logger.notice("Daemon connection interrupted.")
        }

        // The interruption handler will always attempt to to reconnect to the daemon.
        connection.invalidationHandler = { [weak self] in
            self?.logger.notice("Daemon connection invalidated; reconnecting...")
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                self.delegate?.daemonClientDidDisconnect(self)
            }
            self?.workQueue.asyncAfter(deadline: .now() + .seconds(1)) {
                self?.workQueue_connect()
            }
        }
        connection.resume()

        let proxy = connection.remoteObjectProxyWithErrorHandler { [logger] error in
            logger.error("Connection to daemon failed with error \(error).")
        } as? DaemonInterface

        guard let proxy else {
            logger.error("Failed to get daemon proxy.")
            return
        }

        // Force an immediate connection to the daemon.
        proxy.connect { [logger] info in
            DispatchQueue.main.async {
                self.delegate?.daemonClientDidConnect(self)
            }
            logger.info("Connected to daemon \(info)")
        }
    }

    private func workQueue_disconnect() {
        dispatchPrecondition(condition: .onQueue(workQueue))
        connection.invalidate()
    }

    // Reconnect to the daemon following a failed connection.
    private func retryConnection(after deadline: DispatchTime) {

    }

    private func withProxy<T>(completion: @escaping (Result<T, Error>) -> Void, perform: (any DaemonInterface) -> T) {
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            completion(.failure(error))
        } as? DaemonInterface
        guard let proxy else {
            completion(.failure(ReconnectError.invalidDaemonProxy))
            return
        }
        let result = perform(proxy)
        completion(.success(result))
    }

    public func configureSerialDevice(path: String,
                                      configuration: SerialDeviceConfiguration,
                                      completion: @escaping (Result<Void, Error>) -> Void) {
        withProxy(completion: completion) { proxy in
            proxy.configureSerialDevice(path: path, configuration: configuration)
        }
    }

}

extension DaemonClient: DaemonClientInterface {

    public func setIsConnected(_ isConnected: Bool) {
        DispatchQueue.main.async {
            self.delegate?.daemonClient(self, didUpdateDeviceConnectionState: isConnected)
        }
    }

    public func setSerialDevices(_ devices: [SerialDevice]) {
        DispatchQueue.main.async {
            self.delegate?.daemonClient(self, didUpdateSerialDevices: devices)
        }
    }

    public func keepalive(count: Int) {
        logger.notice("Received daemon keepalive (\(count)).")
    }

}
