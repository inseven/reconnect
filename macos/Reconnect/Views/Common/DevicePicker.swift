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
import OpoLuaCore

struct DevicePicker: View {

    @Environment(ApplicationModel.self) private var applicationModel

    @Binding var selection: DeviceModel.ID?

    private let filter: (DeviceModel) -> Bool

    init(selection: Binding<DeviceModel.ID?>, filter: @escaping (DeviceModel) -> Bool = { _ in true }) {
        self._selection = selection
        self.filter = filter
    }

    func updateSelection() {
        // Don't make any changes if the currently selected device is still available.
        guard !applicationModel.deviceModels.contains(where: { $0.id == selection }) else {
            return
        }
        selection = applicationModel.deviceModels.first(where: filter)?.id
    }

    var body: some View {
        LabeledContent("Device") {
            Menu {
                ForEach(applicationModel.deviceModels) { deviceModel in
                    Button {
                        selection = deviceModel.id
                    } label: {
                        Text(deviceModel.name)
                    }
                    .disabled(!filter(deviceModel))
                }
            } label: {
                if let deviceModel = applicationModel.deviceModels.first(where: filter) {
                    Text(deviceModel.name)
                } else {
                    Text("No Compatible Devices")
                }
            }
        }
        .onChange(of: applicationModel.deviceModels, initial: true) {
            updateSelection()
        }
    }

}
