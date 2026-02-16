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

struct DeviceView: View {

    enum Sheet: Identifiable {

        case edit

        var id: Self {
            return self
        }
    }

    @State private var sheet: Sheet? = nil

    private var deviceModel: DeviceModel

    init(deviceModel: DeviceModel) {
        self.deviceModel = deviceModel
    }

    var body: some View {
        InformationView {
            DetailsSection {
                Form {
                    LabeledContent("Name:", value: deviceModel.name)
                    Spacer()
                    LabeledContent("Sync Identiifer:", value: deviceModel.id.uuidString)
                    Spacer()
                    LabeledContent("Type:") {
                        Text(deviceModel.machineType.localizedNameKey)
                    }
                    if let machineInfo = deviceModel.machineInfo {
                        Spacer()
                        LabeledContent("Software Version:", value: machineInfo.softwareVersion)
                        LabeledContent("Language:", value: machineInfo.language)
                        LabeledContent("Unique Id:", value: machineInfo.machineUIDString)
                        Spacer()
                        LabeledContent("Resolution:", value: machineInfo.resolution)
                    }
                }
                .padding()
            } header: {
                Text("Device")
            } footer: {
                HStack {
                    Spacer()
                    Button("Edit...") {
                        sheet = .edit
                    }
                }
            }

            if let ownerInfo = deviceModel.ownerInfo {
                DetailsSection("Owner") {
                    Text(ownerInfo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }

            DetailsSection("Installed Programs") {
                ProgramManagerView(deviceModel: deviceModel)
                    .frame(height: 300)
                    .border(.quaternary)
            }
            
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .edit:
                DeviceEditView(deviceModel: deviceModel)
            }
        }
        .navigationTitle(deviceModel.name)
        .showsDeviceProgress()
    }

}
