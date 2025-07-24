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

struct MainMenu: View {

    @Environment(\.openURL) private var openURL

    @Environment(ApplicationModel.self) var applicationModel

    @ObservedObject var application = Application.shared

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
                        // TODO: Handle this error.
//                        self.error = error
                    }
                }
            case false:
                applicationModel.daemonClient.disableSerialDevice(serialDevice.path) { result in
                    guard case .failure(let error) = result else {
                        return
                    }
                    DispatchQueue.main.async {
                        // TODO: Handle this error.
//                        self.error = error
                    }
                }
            }
        })
    }

    var body: some View {
        @Bindable var applicationModel = applicationModel
        Button {
            applicationModel.openReconnect(.browser)
        } label: {
            Text("My Psion...")
        }
        Divider()
        Button {
            applicationModel.openReconnect(.programManager)
        } label: {
            Text("Add/Remove Programs...")
        }
        .disabled(!applicationModel.isDeviceConnected)
        Divider()
        Button {
            applicationModel.openReconnect(.about)
        } label: {
            Text("About...")
        }
        Menu("Settings") {
            ForEach(applicationModel.serialDevices) { device in
                Toggle(isOn: isEnabledBinding(forSerialDevice: device)) {
                    Text(device.path)
                        .foregroundStyle(device.isAvailable ? .primary : .secondary)
                }
            }
            Divider()
            Toggle("Open at Login", isOn: $application.openAtLogin)
        }
        Divider()
        Button("Check for Updates...") {
            applicationModel.openReconnect(.update)
        }
        Divider()
        Button("Quit") {
            applicationModel.quit()
        }
    }

}
