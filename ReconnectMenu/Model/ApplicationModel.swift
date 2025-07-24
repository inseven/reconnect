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

import os
import SwiftUI

import Interact

import ReconnectCore

@MainActor @Observable
class ApplicationModel: NSObject {

    enum SettingsKey: String {
        case selectedDevices
    }

    var daemonClient = DaemonClient()

    private var selectedDevices: Set<String> {
        didSet {
            // TODO: Can I read these from the group?
            keyedDefaults.set(Array(selectedDevices), forKey: .selectedDevices)
            update()
        }
    }

    private let logger = Logger()
    private let keyedDefaults = KeyedDefaults<SettingsKey>()

    override init() {
        selectedDevices = Set(keyedDefaults.object(forKey: .selectedDevices) as? Array<String> ?? [])
        super.init()
        start()
    }

    func start() {
        daemonClient.connect()  // TODO: Handle errors here!
    }

    @MainActor func quit() {
        // We terminate any running instances of the main Reconnect app as it doesn't make sense for them to run
        // standalone if there's nothing running the PLP sessions.
        // In the future, we should look to inverting our bundle and process architecture and making the menu bar app
        // the parent.
        NSRunningApplication.terminateRunningApplications(withBundleIdentifier: .browserApplicationBundleIdentifier)
        NSApplication.shared.terminate(nil)
    }

    func update() {
        // TODO: I wonder if I could explicitly manage this in the daemon?
        daemonClient.setSelectedDevices(Array(selectedDevices))
    }

    func openReconnect(_ url: URL) {
        let reconnectURL = Bundle.main.bundleURL.deletingLastPathComponents(3)
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
