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

struct SettingsView: View {

    enum SettingsSection {
        case general
        case devices
        case conversions
    }

    @Environment(ApplicationModel.self) private var applicationModel

    var body: some View {
        @Bindable var applicationModel = applicationModel
        TabView(selection: $applicationModel.activeSettingsSection) {

            Form {
                LabeledContent {
                    VStack(alignment: .leading) {
                        Toggle("Run in background", isOn: $applicationModel.openAtLogin)
                        Text("Keep Reconnect running in the menu bar and start at login to automatically connect to your Psion and perform housekeeping tasks.")
                            .multilineTextAlignment(.leading)
                            .font(.footnote)
                            .frame(width: 300, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } label: {
                    Text("Reconnect Menu:")
                        .font(.headline)
                }

                LabeledContent {
                    FilePicker(url: $applicationModel.downloadsURL,
                               options: [.canChooseDirectories, .canCreateDirectories])
                } label: {
                    Text("Downloads:")
                        .font(.headline)
                }

                LabeledContent {
                    VStack(alignment: .leading) {
                        FilePicker(url: $applicationModel.screenshotsURL,
                                   options: [.canChooseDirectories, .canCreateDirectories])
                        Toggle("Reveal in Finder", isOn: $applicationModel.revealScreenshots)
                    }
                } label: {
                    Text("Screenshots:")
                        .font(.headline)
                }
            }
            .scenePadding()
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag(SettingsSection.general)

            Form {

                LabeledContent {
                    VStack(alignment: .leading) {
                        Toggle("Drag and drop", isOn: $applicationModel.convertDraggedFiles)
                        Text("Always convert files when dragging to other applications.")
                            .multilineTextAlignment(.leading)
                            .font(.footnote)
                            .frame(width: 300, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } label: {
                    Text("Convert Files:")
                        .font(.headline)
                }

            }
            .scenePadding()
            .tabItem {
                Label("Conversions", systemImage: "arrow.left.arrow.right")
            }
            .tag(SettingsSection.conversions)

            VStack {
                if applicationModel.isDaemonConnected {
                    if applicationModel.serialDevices.isEmpty {
                        Text("No serial devices connected.")
                    } else {
                        Table(applicationModel.serialDevices) {
                            TableColumn("Name") { device in
                                Text(device.path)
                                    .foregroundStyle(device.isAvailable ? .primary : .secondary)
                            }
                            .width(ideal: 300)
                            TableColumn("Enabled") { device in
                                SerialDeviceEnableToggle(device: device)
                                    .environment(applicationModel)
                            }
                            TableColumn("Baud Rate") { device in
                                SerialDeviceBaudRatePicker(device: device)
                                    .environment(applicationModel)
                            }
                        }
                        .frame(minHeight: 300)
                    }
                } else {
                    Text("Unable to connect to reconnectd.")
                        .foregroundStyle(.secondary)
                }
            }
            .scenePadding()
            .tabItem {
                Label("Serial Devices", systemImage: "cable.connector.horizontal")
            }
            .tag(SettingsSection.devices)

        }
        .frame(width: 600)
    }

}
