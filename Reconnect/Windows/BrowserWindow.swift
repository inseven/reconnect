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
        _browserModel = State(initialValue: BrowserModel(applicationModel: applicationModel,
                                                         transfersModel: transfersModel))
    }

    var body: some Scene {
        Window("My Psion", id: "browser") {
            VStack {
                if applicationModel.isDeviceConnected {
                    BrowserView(browserModel: browserModel)
                } else {
                    if !applicationModel.isDaemonConnected {
                        if applicationModel.launching {
                            ProgressView()
                        } else {
                            ContentUnavailableView {
                                Label("Daemon Not Running", systemImage: "exclamationmark.octagon")
                            } description: {
                                Text("Reconnect is unable to connect to reconnectd. This manages the serial connection and allows both the main Reconnect and menu bar apps to talk to your Psion. Restarting your computer might help.")
                            }
                        }
                    } else if !applicationModel.hasUsableSerialDevices {
                        ContentUnavailableView {
                            Label("Not Connected", systemImage: "cable.connector.slash")
                        } description: {
                            Text("No serial devices available. Make sure you have connected and enabled a serial adapter.")
                        } actions: {
                            SettingsButton("Open Connection Settings...", section: .devices)
                        }
                    } else {
                        ContentUnavailableView {
                            Label {
                                Text("Connecting...")
                            } icon: {
                                ProgressAnimation("cnt")
                            }
                        } actions: {
                            SettingsButton()
                        }
                    }
                }
            }
            .opensSettings()
        }
        .commands {
            SparkleCommands(applicationModel: applicationModel)
            HelpCommands()
            FileCommands(browserModel: browserModel)
            SidebarCommands()
            ToolbarCommands()
            NavigationCommands(browserModel: browserModel)
            DeviceCommands(browserModel: browserModel)
        }
        .environment(applicationModel)
        .environment(transfersModel)
        .environment(browserModel)
        .handlesExternalEvents(matching: [.browser, .settings, .settingsGeneral, .settingsDevices])
    }

}
