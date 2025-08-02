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
    private var connection: NSXPCConnection! // TODO: This is a bit gross
    private var proxy: (any DaemonInterface)?  // TODO: I don't know if I should store this?

    public init() {
        // TODO: Are NSXPCConnections reusable?
    }

    public func connect() {
        workQueue.async { [self] in
            logger.notice("Connecting...")
            connection = NSXPCConnection(machServiceName: .daemonSericeName,
                                         options: [])
            connection.remoteObjectInterface = .daemonInterface
            connection.exportedInterface = .daemonClientInterface
            connection.exportedObject = self
            connection.interruptionHandler = { [weak self] in
                // TODO: What thread are we on here?
                self?.logger.notice("Daemon connection interrupted.")
            }
            connection.invalidationHandler = { [weak self] in
                // TODO: What thread are we on here?
                self?.logger.notice("Daemon connection invalidated; reconnecting...")
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }
                    self.delegate?.daemonClientDidDisconnect(self)
                    // TODO: Track this in some class state and implement some kind of exponential backoff.
                    self.connect()
                }
            }
            connection.resume()

            proxy = connection.remoteObjectProxyWithErrorHandler { error in
                print("XPC error: \(error)")
            } as? DaemonInterface
            guard let proxy else {
                print("Unable to create proxy!")
                return
            }

            // We're forcing a connection here; I seem to remember we always had to do this to force it to actually work.
            proxy.doSomething { response in
                DispatchQueue.main.async {
                    self.delegate?.daemonClientDidConnect(self)
                }
                print("XPC: Response from service: \(response)")
            }
        }
    }

    private func withProxy<T>(completion: @escaping (Result<T, Error>) -> Void, perform: (any DaemonInterface) -> T) {
        proxy = connection.remoteObjectProxyWithErrorHandler { error in
            completion(.failure(error))
        } as? DaemonInterface
        guard let proxy else {
            completion(.failure(ReconnectError.unknown))  // TODO: Better error.
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

// TODO: Can we make this not pubic??
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
