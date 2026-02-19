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
    private var sessions: [NCP.DeviceConfiguration: NCP] = [:]  // Synchronized on main.

    // Dynamic property generating an array of SerialDevice instances that represent the union of available and
    // previously enabled devices. Intended as a convenience for updating connected clients.
    private var serialDevices: [SerialDevice] {
        return Set(knownSerialDevices.keys)
            .union(connectedSerialDevices)
            .sorted()
            .map { path in
                return SerialDevice(path: path,
                                    isAvailable: connectedSerialDevices.contains(path),
                                    configuration: knownSerialDevices[path] ?? SerialDeviceConfiguration())
            }
    }

    // Synchronized on main thread.
    private var connections: [NSXPCConnection] = []
    private var count: Int = 0
    private var connectedSerialDevices: Set<String> = []
    private var knownSerialDevices: [String: SerialDeviceConfiguration] = [:] {
        didSet {
            do {
                try settings.set(codable: knownSerialDevices, forKey: .knownDevices)
            } catch {
                logger.error("Failed to save known serial devices with error \(error).")
            }
        }
    }
    private var connectedDevices: Set<DeviceConnectionDetails> = []

    override init() {
        super.init()
        listener.delegate = self
        serialDeviceMonitor.delegate = self
        do {
            knownSerialDevices = try settings.codable(forKey: .knownDevices, default: [:])
        } catch {
            logger.error("Failed to load known serial devices with error \(error).")
            knownSerialDevices = [:]
        }
    }

    func start() {
        logger.notice("Starting reconnectd...")
        listener.resume()
        serialDeviceMonitor.start()
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

    func updateConnectedSerialDevices() {
        dispatchPrecondition(condition: .onQueue(.main))
        let count = connections.count
        logger.notice("Sending updated serial devices to \(count) clients...")
        withConnections { proxy in
            proxy.setSerialDevices(serialDevices)
        }
    }

    func reconfigureSessionManager() {
        dispatchPrecondition(condition: .onQueue(.main))

        let activeDeviceConfigurations = self.knownSerialDevices
            .compactMap { path, configuration -> NCP.DeviceConfiguration? in
                guard configuration.isEnabled else {  // Remove disabled devices.
                    return nil
                }
                return NCP.DeviceConfiguration(path: path, baudRate: configuration.baudRate)
            }
            .filter { configuration in
                return self.connectedSerialDevices.contains(configuration.path)
            }

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
                ncp.start()
            }
        }
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
                self?.reconfigureSessionManager()
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
            for connectionDetails in connectedDevices {
                proxy.deviceDidConnect(connectionDetails)
            }

            // Update the session manager state.
            reconfigureSessionManager()
        }

        return true
    }

}

extension Daemon: SerialDeviceMonitorDelegate {

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didAddDevices devices: [String]) {
        dispatchPrecondition(condition: .onQueue(.main))
        for device in devices {
            logger.notice("Serial device added '\(device)'.")
            connectedSerialDevices.insert(device)
        }
        reconfigureSessionManager()
        updateConnectedSerialDevices()
    }

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didRemoveDevices devices: [String]) {
        dispatchPrecondition(condition: .onQueue(.main))
        for device in devices {
            logger.notice("Serial device removed '\(device)'")
            connectedSerialDevices.remove(device)
        }
        reconfigureSessionManager()
        updateConnectedSerialDevices()
    }

}

extension Daemon: NCPDelegate {

    func ncp(_ ncp: NCP, didChangeConnectionState isConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        // Right now it connections and disconnections don't seem to be perfectly matched so we explicitly gate these
        // on our internal state to ensure we give clients matched pairs of events.
        if isConnected {
            logger.notice("Device connected on port \(ncp.port).")
            guard !connectedDevices.contains(where: { $0.port == ncp.port }) else {
                return
            }
            let connectionDetails = DeviceConnectionDetails(port: ncp.port)
            connectedDevices.insert(connectionDetails)
            let count = connectedDevices.count
            logger.notice("\(count) connected devices")
            withConnections { proxy in
                proxy.deviceDidConnect(connectionDetails)
            }
        } else {
            logger.notice("Device disconnected on port \(ncp.port).")
            guard let connectionDetails = connectedDevices.first(where: { $0.port == ncp.port }) else {
                return
            }
            connectedDevices.remove(connectionDetails)
            let count = connectedDevices.count
            logger.notice("\(count) connected devices")
            withConnections { proxy in
                proxy.deviceDidDisconnect(connectionDetails)
            }
        }
    }

}

extension Daemon: DaemonInterface {

    public func connect(reply: @escaping (DaemonInfo) -> Void) {
        logger.notice("Received connection message from client.")
        let info = DaemonInfo(version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                              buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        reply(info)
    }

    func configureSerialDevice(path: String, configuration: SerialDeviceConfiguration) {
        logger.notice("Configure serial device (path = '\(path)', configuration = \(configuration))...")
        DispatchQueue.main.async {
            self.knownSerialDevices[path] = configuration
            self.reconfigureSessionManager()
            self.updateConnectedSerialDevices()
        }
    }

}
