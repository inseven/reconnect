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

import SwiftUI

import Interact

struct BrowserWindow: Scene {

    static let id = "browser"

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(TransfersModel.self) private var transfersModel

    var body: some Scene {
        Window("My Psion", id: "browser") {
            ContentView(applicationModel: applicationModel, transfersModel: transfersModel)
                .onOpenURL { url in
                    guard url == .update else {
                        print("Unsupported URL \(url).")
                        return
                    }
                    applicationModel.updaterController.updater.checkForUpdates()
                }
                .handlesExternalEvents(preferring: [.install], allowing: [])
        }
        .commands {
            CommandGroup(before: .appSettings) {
                CheckForUpdatesView(updater: applicationModel.updaterController.updater)
            }
            HelpCommands()
        }
        .environment(applicationModel)
        .handlesExternalEvents(matching: [.browser, .update])
    }

}
