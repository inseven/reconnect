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

struct MachineDetailsGroup: View {

    @Environment(DeviceModel.self) private var deviceModel

    var machineInfo: RemoteCommandServicesClient.MachineInfo {
        return deviceModel.machineInfo
    }

    var type: String {
        return String(machineInfo.machineType.toString())
    }

    var softwareVersion: String {
        return String(format: "%d.%02d(%d)", machineInfo.romMajor, machineInfo.romMinor, machineInfo.romBuild)
    }

    var language: String {
        return String(machineInfo.uiLanguage.toString())
    }

    var machineUID: String {
        let s = String(format: "%llX", deviceModel.machineInfo.machineUID)
        let chunks = stride(from: 0, to: s.count, by: 4).map { i -> String in
            let start = s.index(s.startIndex, offsetBy: i)
            let end = s.index(start, offsetBy: 4, limitedBy: s.endIndex) ?? s.endIndex
            return String(s[start..<end])
        }
        return chunks.joined(separator: "-")
    }

    var resolution: String {
        return String(format: "%dx%d", machineInfo.displayWidth, machineInfo.displayHeight)
    }

    var body: some View {
        DetailsGroup("Machine Information") {
            Form {

                LabeledContent("Type:", value: type)
                LabeledContent("Software Version:", value: softwareVersion)
                LabeledContent("Language:", value: language)
                LabeledContent("Unique Id:", value: machineUID)

                Spacer()

                LabeledContent("Resolution:", value: resolution)

            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}
