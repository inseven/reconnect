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

import ReconnectCore

struct BaudRatePicker: View {

    @Environment(ApplicationModel.self) private var applicationModel

    @State var error: Error? = nil

    let device: SerialDevice

    init(device: SerialDevice) {
        self.device = device
    }

    func name(baudRate: Int32) -> String {
        if baudRate == 0 {
            return "Disabled"
        } else {
            return String(format: "%d", baudRate)
        }
    }

    func binding() -> Binding<Int32> {
        return Binding {
            return device.configuration.baudRate
        } set: { baudRate in
            let configuration = SerialDeviceConfiguration(baudRate: baudRate)
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
        Picker(selection: binding()) {
            ForEach(SerialDeviceConfiguration.availableBaudRates, id: \.self) { baudRate in
                Text(name(baudRate: baudRate))
                    .tag(baudRate)
            }
        } label: {
            EmptyView()
        }
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(device.isAvailable ? .primary : .secondary)
        .disabled(!device.isAvailable)
    }

}
