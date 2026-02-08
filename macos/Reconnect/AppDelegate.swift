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

import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let applicationModel = ApplicationModel()

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.isFileURL {
                applicationModel.showInstallerWindow(url: url)
            } else if url == .update {
                applicationModel.updaterController.updater.checkForUpdates()
            } else {
                print("Ignoring URL '\(url.absoluteString)'...")
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !applicationModel.longRunningOperations.isEmpty else {
            return .terminateNow
        }
        let alert = NSAlert()
        alert.messageText = "Quit Reconnect?"
        alert.informativeText = "Reconnect is currently performing long running operations."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        let response = alert.runModal()
        return response == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        if !applicationModel.openAtLogin {
            applicationModel.terminateRunningMenuApplications()
        }
    }

}
