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

import Interact

import ReconnectCore

class Daemon: NSObject {

    enum SettingsKey: String {
        case knownDevices
    }

    private let logger = Logger(subsystem: "reconnectd", category: "Daemon")
    private let settings = KeyedDefaults<SettingsKey>()
    private let listener = NSXPCListener(machServiceName: .daemonSericeName)
    private let serialDeviceMonitor = SerialDeviceMonitor()
    private let sessionManager = NCPSessionManager()

    // Dynamic property generating an array of SerialDevice instances that represent the union of available and
    // previously enabled devices. Intended as a convenience for updating connected clients.
    private var serialDevices: [SerialDevice] {
        return Set(knownDevices.keys)
            .union(connectedDevices)
            .sorted()
            .map { path in
                return SerialDevice(path: path,
                                    isAvailable: connectedDevices.contains(path),
                                    configuration: knownDevices[path] ?? SerialDeviceConfiguration())
            }
    }

    // Synchronized on main thread.
    private var connections: [NSXPCConnection] = []
    private var count: Int = 0
    private var connectedDevices: Set<String> = []
    private var knownDevices: [String: SerialDeviceConfiguration] = [:] {
        didSet {
            do {
                try settings.set(codable: knownDevices, forKey: .knownDevices)
            } catch {
                logger.error("Failed to save known serial devices with error \(error).")
            }
        }
    }
    private var isConnected: Bool = false

    override init() {
        super.init()
        listener.delegate = self
        serialDeviceMonitor.delegate = self
        sessionManager.delegate = self
        do {
            knownDevices = try settings.codable(forKey: .knownDevices, default: [:])
        } catch {
            logger.error("Failed to load known serial devices with error \(error).")
            knownDevices = [:]
        }
    }

    func start() {
        logger.notice("Starting reconnectd...")
        listener.resume()
        serialDeviceMonitor.start()
        sessionManager.start()
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
        logger.notice("Sending client keepalive (\(self.count))...")
        for connection in connections {
            guard let proxy = connection.remoteObjectProxy as? DaemonClientInterface else {
                continue
            }
            proxy.keepalive(count: count)
        }
    }

    fileprivate func withConnections(perform: (_ proxy: DaemonClientInterface) -> Void) {
        for connection in connections {
            guard let proxy = connection.remoteObjectProxy as? DaemonClientInterface else {
                logger.error("Failed to get remote proxy for update.")
                continue
            }
            perform(proxy)
        }
    }

    func updateConnectedDevices() {
        dispatchPrecondition(condition: .onQueue(.main))
        let count = connections.count
        logger.notice("Sending updated serial devices to \(count) clients...")
        withConnections { proxy in
            proxy.setSerialDevices(serialDevices)
        }
    }

    func reconfigureSessionManager() {
        dispatchPrecondition(condition: .onQueue(.main))
        let devices = self.knownDevices.compactMap { path, configuration -> NCPSessionManager.DeviceConfiguration? in
            guard configuration.isEnabled else {  // Remove disabled devices.
                return nil
            }
            return NCPSessionManager.DeviceConfiguration(path: path, baudRate: configuration.baudRate)
        }.filter { configuration in
            return self.connectedDevices.contains(configuration.path)
        }
        self.sessionManager.setDevices(devices)
    }

}

extension Daemon: NSXPCListenerDelegate {

    @objc
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))

        logger.notice("New XPC connection...")
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

            guard let proxy = newConnection.remoteObjectProxy as? DaemonClientInterface else {
                logger.error("Failed to get remote proxy for new connection.")
                return
            }
            // Send the current state.
            proxy.setSerialDevices(serialDevices)
            proxy.setIsConnected(isConnected)
        }

        return true
    }

}

extension Daemon: SerialDeviceMonitorDelegate {

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didAddDevice device: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("Serial device added '\(device)'.")
        connectedDevices.insert(device)
        reconfigureSessionManager()
        updateConnectedDevices()
    }

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didRemoveDevice device: String) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("Serial device removed '\(device)'")
        connectedDevices.remove(device)
        reconfigureSessionManager()
        updateConnectedDevices()
    }

}

extension Daemon: NCPSessionManagerDelegate {

    func sessionManager(_ sessionManager: NCPSessionManager, didChangeConnectionState isConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("Device connection state changed (isConnected = \(isConnected)).")
        self.isConnected = isConnected
        withConnections { proxy in
            proxy.setIsConnected(isConnected)
        }
    }

}

extension Daemon: DaemonInterface {

    // TODO: Rename and return version and build.
    public func doSomething(reply: @escaping (String) -> Void) {
        print("Service received request!")
        reply("Hello from XPC Service!")
    }

    func configureSerialDevice(path: String, configuration: SerialDeviceConfiguration) {
        logger.notice("Configure serial device (path = '\(path)', configuration = \(configuration))...")
        DispatchQueue.main.async {
            self.knownDevices[path] = configuration
            self.reconfigureSessionManager()
            self.updateConnectedDevices()
        }
    }

}
