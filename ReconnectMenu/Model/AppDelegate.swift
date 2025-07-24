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
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

//    private let logger = Logger()
    private let service = SMAppService.agent(plistName: "uk.co.jbmorley.reconnect.apps.apple.reconnectd.plist")

    func applicationDidFinishLaunching(_ notification: Notification) {
        enableDaemon()
    }

    func applicationWillTerminate(_ notification: Notification) {
        disableDaemon()
    }

    func enableDaemon() {
        do {
//            logger.notice("Registering reconnectd...")
            try SMAppService.agent(plistName: "uk.co.jbmorley.reconnect.apps.apple.reconnectd.plist").register()
//            logger.notice("Successfully registered reconnectd")
        } catch {
//            logger.error("Failed to register reconnectd with error '\(error)'")
        }
    }

    func disableDaemon() {
        do {
//            logger.notice("Unregistering reconnectd...")
            try SMAppService.agent(plistName: "uk.co.jbmorley.reconnect.apps.apple.reconnectd.plist").unregister()
//            logger.notice("Successfully unregistered reconnectd")
            // TODO: Wait for the daemon to disappear before continuing.
        } catch {
//            logger.error("Failed to unregister reconnectd with error '\(error)'")
        }
    }

}
