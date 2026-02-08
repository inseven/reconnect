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

import os
import SwiftUI

import Interact

import ReconnectCore

@MainActor @Observable
class ApplicationModel: NSObject {

    let daemonClient = DaemonClient()

    private let logger = Logger()

    // Daemon state; synchronized on main.
    var isDaemonConnected = false
    var isDeviceConnected = false

    override init() {
        super.init()
        daemonClient.delegate = self
        start()
    }

    func start() {
        daemonClient.connect()
    }

    @MainActor func quit() {

        // Disconnect from the daemon.
        daemonClient.disconnect()

        // We terminate any running instances of the main Reconnect app as it doesn't make sense for them to run
        // standalone if there's nothing running the PLP sessions.
        // Note that we don't wait for the main Reconnect browser app to quit here as it's sufficient to trust that it's
        // quitting, and the main app will also attempt to quit the menu bar (if running in the background is disabled)
        // which can lead to livelock.
        NSRunningApplication.terminateRunningApplications(bundleIdentifier: .browserApplicationBundleIdentifier,
                                                          waitForCompletion: false)

        NSApplication.shared.terminate(nil)
    }

    func openReconnect(_ url: URL) {
        // Our app is at in Reconnect.app/Contents/Library/LoginItems/Reconnect Menu.app.
        let reconnectURL = Bundle.main.bundleURL.deletingLastPathComponents(4)
        let openConfiguration = NSWorkspace.OpenConfiguration()
        openConfiguration.allowsRunningApplicationSubstitution = false
        openConfiguration.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: reconnectURL, configuration: openConfiguration) { app, error in
            guard let app else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                app.activate()
            }
        }
    }

}

extension ApplicationModel: DaemonClientDelegate {

    func daemonClientDidConnect(_ daemonClient: DaemonClient) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.isDaemonConnected = true
    }
    
    func daemonClientDidDisconnect(_ daemonClient: DaemonClient) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.isDaemonConnected = false
    }

    func daemonClient(_ daemonClient: DaemonClient, didUpdateDeviceConnectionState isDeviceConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.isDeviceConnected = isDeviceConnected

    }
    
    func daemonClient(_ daemonClient: DaemonClient, didUpdateSerialDevices serialDevices: [SerialDevice]) {
        dispatchPrecondition(condition: .onQueue(.main))
    }

}
