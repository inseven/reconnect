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

import Interact

import ReconnectCore

struct BrowserWindow: Scene {

    static let id = "browser"

    private let applicationModel: ApplicationModel
    private let libraryModel: LibraryModel
    private let navigationModel: NavigationModel<BrowserSection>

    init(applicationModel: ApplicationModel,
         libraryModel: LibraryModel,
         navigationModel: NavigationModel<BrowserSection>) {
        self.applicationModel = applicationModel
        self.libraryModel = libraryModel
        self.navigationModel = navigationModel
    }

    var body: some Scene {
        Window("My Psion", id: "browser") {
            BrowserView(libraryModel: libraryModel)
                .opensSettings()
        }
        .commands {
            SparkleCommands(applicationModel: applicationModel)
            HelpCommands()
            FileCommands()
            RefreshCommands()
            SidebarCommands()
            ToolbarCommands()
            NavigationCommands()
            DeviceCommands()
        }
        .environment(applicationModel)
        .environment(applicationModel.backupsModel)
        .environment(applicationModel.transfersModel)
        .environment(navigationModel)
        .handlesExternalEvents(matching: [.browser, .settings, .settingsGeneral, .settingsDevices])
    }

}
