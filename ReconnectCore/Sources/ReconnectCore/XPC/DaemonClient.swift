//
//  ConnectionStatus.swift
//  ReconnectCore
//
//  Created by Jason Barrie Morley on 19/07/2025.
//

import Foundation
import SwiftUI

// Callbacks occur on main.
public protocol DaemonClientDelegate: NSObject {

    func daemonDidUpdateSerialDevices(devices: [SerialDevice])

}

@Observable
public class DaemonClient {

    public weak var delegate: DaemonClientDelegate? = nil

    public var isConnectedToDaemon: Bool = false
    public var isConnected: Bool = false
    public var devices: Set<String> = []

    private let connection: NSXPCConnection
    private var proxy: (any DaemonInterface)?

    public init() {
        connection = NSXPCConnection(machServiceName: "uk.co.jbmorley.reconnect.apps.apple.xpc.daemon", options: [])
    }

    public func connect() {
        connection.remoteObjectInterface = NSXPCInterface(with: DaemonInterface.self)
        connection.exportedInterface = NSXPCInterface(with: DaemonClientInterface.self)
        connection.exportedObject = self

        // TODO: Retry logic?
        connection.interruptionHandler = {
            print("Connection interrupted")
            DispatchQueue.main.async {
                print("connection interrupted")
                self.isConnectedToDaemon = false
            }
        }
        connection.invalidationHandler = {
            print("Connection invalidated")
            DispatchQueue.main.async {
                print("connection interrupted")
                self.isConnectedToDaemon = false
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

    // TODO: Set and unset?
    public func setSelectedDevices(_ devices: [String]) {
        proxy?.setSelectedSerialDevices(devices)
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
