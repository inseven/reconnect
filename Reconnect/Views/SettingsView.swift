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

import ReconnectCore

struct SettingsView: View {

    enum SettingsSection {
        case general
        case connection
    }

    @Environment(ApplicationModel.self) private var applicationModel

    var body: some View {
        @Bindable var applicationModel = applicationModel
        NavigationSplitView {
            List(selection: $applicationModel.activeSettingsSection) {
                Label("General", image: "Extras16")
                    .tag(SettingsSection.general)
                Label("Connection", image: "Connected16")
                    .tag(SettingsSection.connection)
            }
            .toolbar(removing: .sidebarToggle)
        } detail: {
            switch applicationModel.activeSettingsSection {
            case .general:
                Form {
                    Section {
                        Toggle("Run in Background", isOn: $applicationModel.openAtLogin)
                    } footer: {
                        HStack {
                            Text("Keep Reconnect running in the menu bar and start at login to automatically connect to your Psion and perform housekeeping tasks.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .font(.callout)
                            Spacer()
                        }
                    }
                    Section("Downloads") {
                        FilePicker("Destination",
                                   url: $applicationModel.downloadsURL,
                                   options: [.canChooseDirectories, .canCreateDirectories])
                    }
                    Section("Screenshots") {
                        FilePicker("Destination",
                                   url: $applicationModel.screenshotsURL,
                                   options: [.canChooseDirectories, .canCreateDirectories])
                        Toggle("Reveal Screnshots", isOn: $applicationModel.revealScreenshots)
                    }
                }
                .navigationTitle("General")
            case .connection:
                Form {
                    Section("Serial Devices") {
                        if applicationModel.isDaemonConnected {
                            ForEach(Array(applicationModel.serialDevices)) { device in
                                SerialDeviceSettingsView(device: device)
                            }
                        } else {
                            Text("Unable to connect to reconnectd.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Connections")
            }
        }
        .formStyle(.grouped)
        .frame(width: 600)
        .frame(minHeight: 600)
    }

}
