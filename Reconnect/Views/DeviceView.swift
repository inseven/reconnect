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

struct InformationView<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scenePadding()
        }
        .background(.textBackgroundColor)
    }

}

struct DeviceView: View {

    @Environment(DeviceModel.self) private var deviceModel

    var body: some View {
        InformationView {

            TabularDetailsSection("Device") {
                LabeledContent("Name:", value: deviceModel.deviceConfiguration.name)
                LabeledContent("Sync Identiifer:", value: deviceModel.deviceConfiguration.id.uuidString)
            }

            MachineDetailsGroup(machineInfo: deviceModel.machineInfo)

            DetailsGroup("Installed Programs") {
                ProgramManagerView(deviceModel: deviceModel)
                    .frame(height: 300)
                    .border(.quaternary)
            }
            
        }
        .navigationTitle("My Psion")
        .showsDeviceProgress()
    }

}
