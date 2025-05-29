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

    @State private var browserModel: BrowserModel

    private let applicationModel: ApplicationModel
    private let transfersModel: TransfersModel

    init(applicationModel: ApplicationModel, transfersModel: TransfersModel) {
        self.applicationModel = applicationModel
        self.transfersModel = transfersModel
        _browserModel = State(initialValue: BrowserModel(transfersModel: transfersModel))
    }

    var body: some Scene {
        Window("My Psion", id: "browser") {
            BrowserView(browserModel: browserModel)
                .onOpenURL { url in
                    guard url == .update else {
                        print("Unsupported URL \(url).")
                        return
                    }
                    applicationModel.updaterController.updater.checkForUpdates()
                }
                .handlesExternalEvents(preferring: [.install], allowing: [])
                .onOpenURL { url in
                    print(url)
                }
        }
        .commands {
            SparkleCommands(applicationModel: applicationModel)
            HelpCommands()
            BrowserCommands(browserModel: browserModel)
            SidebarCommands()
            ToolbarCommands()
        }
        .environment(applicationModel)
        .environment(transfersModel)
        .environment(browserModel)
        .handlesExternalEvents(matching: [.browser, .update])
    }

}
