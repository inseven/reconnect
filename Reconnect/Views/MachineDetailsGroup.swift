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

import ReconnectCore

extension RemoteCommandServicesClient.MachineInfo {

    var softwareVersion: String {
        return String(format: "%d.%02d(%d)", romMajor, romMinor, romBuild)
    }

    var language: String {
        return String(uiLanguage.toString())
    }

    var machineUIDString: String {
        let s = String(format: "%llX", machineUID)
        let chunks = stride(from: 0, to: s.count, by: 4).map { i -> String in
            let start = s.index(s.startIndex, offsetBy: i)
            let end = s.index(start, offsetBy: 4, limitedBy: s.endIndex) ?? s.endIndex
            return String(s[start..<end])
        }
        return chunks.joined(separator: "-")
    }

    var resolution: String {
        return String(format: "%dx%d", displayWidth, displayHeight)
    }

}

struct MachineDetailsGroup: View {

    @Environment(DeviceModel.self) private var deviceModel

    var machineInfo: RemoteCommandServicesClient.MachineInfo?

    var type: String {
        return String("\(deviceModel.machineType)")
    }

    var body: some View {
        DetailsSection("Machine Information") {
            Form {

                LabeledContent {
                    Text(deviceModel.machineType.localizedNameKey)
                } label: {
                    Text("Type:")
                }

                if let machineInfo {
                    Spacer()
                    LabeledContent("Software Version:", value: machineInfo.softwareVersion)
                    LabeledContent("Language:", value: machineInfo.language)
                    LabeledContent("Unique Id:", value: machineInfo.machineUIDString)
                    Spacer()
                    LabeledContent("Resolution:", value: machineInfo.resolution)
                }

            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}
