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

    @Environment(ApplicationModel.self) private var applicationModel

    @State var error: Error? = nil

    func isEnabledBinding(forSerialDevice serialDevice: SerialDevice) -> Binding<Bool> {
        return Binding(get: {
            return serialDevice.isEnabled
        }, set: { isEnabled in
            switch isEnabled {
            case true:
                applicationModel.daemonClient.enableSerialDevice(serialDevice.path) { result in
                    guard case .failure(let error) = result else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.error = error
                    }
                }
            case false:
                applicationModel.daemonClient.disableSerialDevice(serialDevice.path) { result in
                    guard case .failure(let error) = result else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.error = error
                    }
                }
            }
        })
    }

    var body: some View {
        @Bindable var applicationModel = applicationModel
        Form {
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
            Section("Serial Devices") {
                if applicationModel.isDaemonConnected {
                    ForEach(Array(applicationModel.serialDevices)) { device in
                        Toggle(device.path, isOn: isEnabledBinding(forSerialDevice: device))
                            .foregroundStyle(device.isAvailable ? .primary : .secondary)
                            .disabled(!device.isAvailable)
                    }
                } else {
                    Text("Unable to connect to reconnectd.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .presents($error)
        .frame(width: 500)
        .frame(minHeight: 600)
    }

}
