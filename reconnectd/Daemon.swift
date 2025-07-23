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

import ReconnectCore

class Daemon: NSObject {

    private let logger = Logger()
    private let listener = NSXPCListener(machServiceName: .daemonSericeName)
    private let serialDeviceMonitor = SerialDeviceMonitor()
    private let server: Server = Server()

    // Synchronized on main thread.
    private var connections: [NSXPCConnection] = []
    private var count: Int = 0
    private var connectedDevices: Set<String> = []
    private var selectedDevices: Set<String> = []
    private var isConnected: Bool = false

    override init() {
        super.init()
        listener.delegate = self
        serialDeviceMonitor.delegate = self
        server.delegate = self
    }

    func start() {
        logger.notice("Starting reconnectd...")
        listener.resume()
        serialDeviceMonitor.start()
        server.start()
        ping()
    }

    func ping() {
        dispatchPrecondition(condition: .onQueue(.main))

        // Ensure we always schedule another ping.
        // TODO: We should do this with a scheduled timer.
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                self.ping()
            }
        }

        count = count + 1
        guard !connections.isEmpty else {
            return
        }
        logger.notice("ping")
        for connection in connections {
            guard let proxy = connection.remoteObjectProxy as? DaemonClientInterface else {
                continue
            }
            proxy.connectionStatusDidChange(to: count)
        }
    }

    fileprivate func withConnections(perform: (_ proxy: DaemonClientInterface) -> Void) {
        for connection in connections {
            guard let proxy = connection.remoteObjectProxy as? DaemonClientInterface else {
                continue
            }
            perform(proxy)
        }
    }

    func updateConnectedDevices() {
        dispatchPrecondition(condition: .onQueue(.main))
        withConnections { proxy in
            proxy.setSerialDevices(Array(connectedDevices))
        }
    }
}

extension Daemon: NSXPCListenerDelegate {

    @objc
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))

        logger.notice("incoming connection")
        newConnection.exportedInterface = NSXPCInterface(with: DaemonInterface.self)
        newConnection.remoteObjectInterface = NSXPCInterface(with: DaemonClientInterface.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { [weak self] in
            dispatchPrecondition(condition: .notOnQueue(.main))
            DispatchQueue.main.sync {
                self?.connections.removeAll { $0.isEqual(newConnection) }
            }
        }
        newConnection.resume()

        DispatchQueue.main.sync {
            self.connections.append(newConnection)

            // Send the initial state.
            guard let proxy = newConnection.remoteObjectProxy as? DaemonClientInterface else {
                return
            }
            proxy.setSerialDevices(Array(connectedDevices))
            proxy.setIsConnected(isConnected)
        }

        return true
    }

}

extension Daemon: SerialDeviceMonitorDelegate {

    func serialDeviceMonitor(serialDeviceMonitor: ReconnectCore.SerialDeviceMonitor, didAddDevice device: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("add serial device '\(device)'")
        self.connectedDevices.insert(device)
        withConnections { proxy in
            proxy.addSerialDevice(device)
        }
    }

    func serialDeviceMonitor(serialDeviceMonitor: ReconnectCore.SerialDeviceMonitor, didRemoveDevice device: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("remove serial device '\(device)'")
        self.connectedDevices.remove(device)
        withConnections { proxy in
            proxy.removeSerialDevice(device)
        }
    }

}

extension Daemon: ServerDelegate {

    func server(server: ReconnectCore.Server, didChangeConnectionState isConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("isConnected = \(isConnected)")
        self.isConnected = isConnected
        withConnections { proxy in
            proxy.setIsConnected(isConnected)
        }
    }

}

extension Daemon: DaemonInterface {

    // TODO: Connect / start.
    // TOOD: This could be a version message?
    public func doSomething(reply: @escaping (String) -> Void) {
        print("Service received request!")
        reply("Hello from XPC Service!")
    }

    public func setSelectedSerialDevices(_ selectedSerialDevices: [String]) {
        logger.notice("Updating selected serial devices...")
        DispatchQueue.main.async {
            self.selectedDevices = Set(selectedSerialDevices)
            self.server.setDevices(self.selectedDevices.intersection(self.connectedDevices).sorted())
        }
    }

}
