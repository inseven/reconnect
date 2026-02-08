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

struct SerialDeviceEnableToggle: View {

    @Environment(ApplicationModel.self) private var applicationModel

    @State var error: Error? = nil

    let device: SerialDevice

    init(device: SerialDevice) {
        self.device = device
    }

    func binding() -> Binding<Bool> {
        return Binding {
            return device.configuration.isEnabled
        } set: { enabled in
            let configuration = device
                .configuration
                .setting(isEnabled: enabled)
            applicationModel.daemonClient.configureSerialDevice(path: device.path,
                                                                configuration: configuration) { result in
                guard case .failure(let error) = result else {
                    return
                }
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }

    var body: some View {
        Toggle(isOn: binding()) {
            EmptyView()
        }
    }

}
