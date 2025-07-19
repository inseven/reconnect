//
//  main.swift
//  reconnectd
//
//  Created by Jason Barrie Morley on 19/07/2025.
//

import Foundation

import ReconnectCore

print("Hello, World!")

class ListenerDelegate: NSObject, NSXPCListenerDelegate {

    @objc
    nonisolated func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        print("Incoming!")
        newConnection.exportedInterface = NSXPCInterface(with: ConnectionInterface.self)
        newConnection.exportedObject = MyXPCService()
        newConnection.resume()
        return true
    }

}

let delegate = ListenerDelegate()

let listener = NSXPCListener(machServiceName: "uk.co.jbmorley.reconnect.apps.apple.xpc.daemon")
listener.delegate = delegate
listener.resume()

DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
    print("Timeout!")
}

RunLoop.main.run()
