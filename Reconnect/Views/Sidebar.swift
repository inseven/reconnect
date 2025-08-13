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

struct Sidebar: View {

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(NavigationHistory.self) private var navigationHistory

    var section: Binding<BrowserSection> {
        return Binding {
            switch navigationHistory.currentItem?.section {
            case .connecting:
                return .connecting
            case .device(let deviceId):
                return .device(deviceId)
            case .directory(let deviceId, let driveInfo, _):
                return .drive(deviceId, driveInfo)
            case .drive(let deviceId, let driveInfo):
                return .drive(deviceId, driveInfo)
            case .program:
                return .softwareIndex
            case .softwareIndex:
                return .softwareIndex
            case .none:
                return .connecting
            }
        } set: { section in
            navigationHistory.navigate(section)
        }
    }

    var body: some View {
        List(selection: section) {

            Section("Devices") {
                OutlineGroup(applicationModel.sidebarDevices, children: \.children) { item in
                    Label(item.section.title, image: item.section.image)
                        .tag(item.section)
                }
            }

            Section("Library") {
                SectionLabel(section: .softwareIndex)
                    .tag(BrowserSection.softwareIndex)
            }

        }

    }

}
