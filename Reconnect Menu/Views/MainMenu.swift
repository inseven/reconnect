// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024 Jason Morley
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

struct MainMenu: View {

    @Environment(\.openURL) private var openURL

    @Environment(ApplicationModel.self) var applicationModel

    @ObservedObject var application = Application.shared

    var body: some View {
        @Bindable var applicationModel = applicationModel
        Button {
            openURL(.browser)
        } label: {
            Text("My Psion...")
        }
        .disabled(!applicationModel.isConnected)
        Divider()
        Menu("Settings") {
            ForEach(applicationModel.devices) { device in
                Toggle(isOn: device.enabled) {
                    Text(device.path)
                        .foregroundStyle(device.available ? .primary : .secondary)
                }
            }
            Divider()
            Toggle("Convert Files", isOn: $applicationModel.convertFiles)
            Toggle("Open at Login", isOn: $application.openAtLogin)
        }
//        Divider()
//        CheckForUpdatesView(updater: applicationModel.updaterController.updater)
        Divider()
        Button("Quit") {
            applicationModel.quit()
        }
    }

}
