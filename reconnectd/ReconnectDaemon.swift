//
//  main.swift
//  reconnectd
//
//  Created by Jason Barrie Morley on 19/07/2025.
//

import Foundation
import os

import ReconnectCore

class ReconnectDaemon: NSObject {

    private let logger = Logger()
    private let listener = NSXPCListener(machServiceName: "uk.co.jbmorley.reconnect.apps.apple.xpc.daemon")
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
            guard let proxy = connection.remoteObjectProxy as? ConnectionStatusObserver else {
                continue
            }
            proxy.connectionStatusDidChange(to: count)
        }
    }

    fileprivate func withConnections(perform: (_ proxy: ConnectionStatusObserver) -> Void) {
        for connection in connections {
            guard let proxy = connection.remoteObjectProxy as? ConnectionStatusObserver else {
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

extension ReconnectDaemon: NSXPCListenerDelegate {

    @objc
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))

        logger.notice("incoming connection")
        newConnection.exportedInterface = NSXPCInterface(with: ConnectionInterface.self)
        newConnection.remoteObjectInterface = NSXPCInterface(with: ConnectionStatusObserver.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { [weak self] in
            dispatchPrecondition(condition: .onQueue(.main))
            DispatchQueue.main.sync {
                self?.connections.removeAll { $0.isEqual(newConnection) }
            }
        }
        newConnection.resume()

        DispatchQueue.main.sync {
            self.connections.append(newConnection)

            // Send the initial state.
            guard let proxy = newConnection.remoteObjectProxy as? ConnectionStatusObserver else {
                return
            }
            proxy.setSerialDevices(Array(connectedDevices))
            proxy.setIsConnected(isConnected)
        }

        return true
    }

}

extension ReconnectDaemon: SerialDeviceMonitorDelegate {

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

extension ReconnectDaemon: ServerDelegate {

    func server(server: ReconnectCore.Server, didChangeConnectionState isConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        logger.notice("isConnected = \(isConnected)")
        self.isConnected = isConnected
        withConnections { proxy in
            proxy.setIsConnected(isConnected)
        }
    }

}

extension ReconnectDaemon: ConnectionInterface {

    // TODO: Connect / start.
    public func doSomething(reply: @escaping (String) -> Void) {
        print("Service received request!")
        reply("Hello from XPC Service!")
    }

    public func setSelectedSerialDevices(_ selectedSerialDevices: [String]) {
        logger.notice("set selected serial deices \(selectedSerialDevices)")
        DispatchQueue.main.async {  // TODO Sync?
            self.selectedDevices = Set(selectedSerialDevices)
            self.server.setDevices(self.selectedDevices.intersection(self.connectedDevices).sorted())
        }
    }

}
