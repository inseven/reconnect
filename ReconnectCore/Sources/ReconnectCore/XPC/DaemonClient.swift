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
public protocol DaemonClientDelegate: NSObject {

    func daemonDidUpdateSerialDevices(devices: [SerialDevice])

}

@Observable
public class DaemonClient {

    enum ConnectionState {
        case idle
        case connecting
        case connected
    }

    public weak var delegate: DaemonClientDelegate? = nil

    // Synchornized on main.
    // TODO: Ultimately this class shouldn't store state.
    public var isConnectedToDaemon: Bool = false
    public var isConnected: Bool = false
    public var devices: Set<String> = []

    private let logger = Logger()
    private let workQueue = DispatchQueue(label: "DaemonClient.workQueue")

    // Synchronized on workQueue.
    private let state: ConnectionState = .idle
    private var connection: NSXPCConnection! // TODO: This is a bit gross
    private var proxy: (any DaemonInterface)?  // TODO: I don't know if I should store this?

    public init() {
        // TODO: Are NSXPCConnections reusable?
    }

    public func connect() {
        workQueue.async { [self] in
            logger.notice("Connecting...")
            connection = NSXPCConnection(machServiceName: "uk.co.jbmorley.reconnect.apps.apple.xpc.daemon",
                                         options: [])
            connection.remoteObjectInterface = NSXPCInterface(with: DaemonInterface.self)
            connection.exportedInterface = NSXPCInterface(with: DaemonClientInterface.self)
            connection.exportedObject = self
            connection.interruptionHandler = { [weak self] in
                // TODO: What thread are we on here?
                self?.logger.notice("Daemon connection interrupted.")
            }
            connection.invalidationHandler = { [weak self] in
                // TODO: What thread are we on here?
                self?.logger.notice("Daemon connection invalidated; reconnecting...")
                DispatchQueue.main.async {
                    self?.isConnectedToDaemon = false
                    self?.connect()
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
                    print("connected = true")
                    self.isConnectedToDaemon = true
                }
                print("XPC: Response from service: \(response)")
            }
        }
    }

    // TODO: Set and unset?
    public func setSelectedDevices(_ devices: [String]) {
        proxy?.setSelectedSerialDevices(devices)
    }

    public func restart(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
            completion(.failure(error))
        }) as? DaemonInterface else {
            completion(.failure(ReconnectError.unknown))  // TODO: Correct error!
            return
        }
        proxy.restart()
        completion(.success(()))
    }

}

// TODO: Can we make this not pubic??
extension DaemonClient: DaemonClientInterface {

    public func setIsConnected(_ isConnected: Bool) {
        DispatchQueue.main.async {
            self.isConnected = isConnected
        }
    }

    public func setSerialDevices(_ devices: [String]) {
        print("set serial devices \(devices)")
        DispatchQueue.main.async {
            self.devices = Set(devices)
        }
    }

    public func addSerialDevice(_ device: String) {
        print("add serial device \(device)")
        DispatchQueue.main.async {
            self.devices.insert(device)
        }
    }
    
    public func removeSerialDevice(_ device: String) {
        print("remove serial device \(device)")
        DispatchQueue.main.async {
            self.devices.remove(device)
        }
    }

    public func connectionStatusDidChange(to newStatus: Int) {
        print("status -> \(newStatus)")
    }

}
