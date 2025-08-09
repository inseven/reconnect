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

import PsionSoftwareIndex

@MainActor
struct BrowserView: View {

    @Environment(\.openWindow) private var openWindow

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(SceneModel.self) private var sceneModel
    @Environment(TransfersModel.self) private var transfersModel
    @Environment(NavigationHistory.self) private var navigationHistory

    init() {
    }

    var body: some View {

        NavigationSplitView {
            Sidebar()
        } detail: {
            switch navigationHistory.currentItem?.section {
            case .connecting:
                DisconnectedView()
            case .drive(let driveInfo):
                DirectoryView(applicationModel: applicationModel,
                              transfersModel: transfersModel,
                              navigationHistory: navigationHistory,
                              driveInfo: driveInfo,
                              path: driveInfo.path)
                .id(driveInfo.path)
            case .directory(let driveInfo, let path):
                DirectoryView(applicationModel: applicationModel,
                              transfersModel: transfersModel,
                              navigationHistory: navigationHistory,
                              driveInfo: driveInfo,
                              path: path)
                .id(path)
            case .device:
                DeviceView()
                    .focusesDevice()
            case .softwareIndex:
                PsionSoftwareIndexView { release in
                    return release.kind == .installer
                } completion: { item in
                }
            case .none:
                Text("Nothing selected!")
            }

        }
        .toolbar(id: "main") {

            NavigationToolbar()

            ToolsToolbar()
            ToolbarSpacer(id: "spacer-1")
            FileToolbar()
            ToolbarSpacer(id: "spacer-2")
            RefreshToolbar()

        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: sceneModel.section) { oldValue, newValue in
            guard navigationHistory.currentItem?.section != newValue else {
                return
            }
            navigationHistory.navigate(newValue)
        }
        .onChange(of: navigationHistory.currentItem) { oldValue, newValue in
            // TODO: This is messy; tidy it up.
            guard sceneModel.section != newValue?.section else {
                return
            }
            // Remap `.directory` to `.drive` for the sidebar entries.
            let newSection = if case let .directory(driveInfo, _) = newValue?.section {
                BrowserSection.drive(driveInfo)
            } else {
                newValue?.section
            }
            guard sceneModel.section != newSection else {
                return
            }
            guard let newSection else {
                return
            }
            sceneModel.section = newSection
        }
        .onChange(of: applicationModel.devices) { oldValue, newValue in
            if newValue.isEmpty {
                switch sceneModel.section {
                case .connecting, .softwareIndex:
                    break
                case .device, .directory, .drive:
                    sceneModel.section = .connecting
                }
            } else {
                navigationHistory.navigate(.device)
            }
        }
    }

}
