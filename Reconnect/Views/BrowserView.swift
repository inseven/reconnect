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

@MainActor
struct BrowserView: View {

    @Environment(\.openWindow) private var openWindow

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(TransfersModel.self) private var transfersModel
    @Environment(NavigationHistory.self) private var navigationHistory

    @StateObject var libraryModel: LibraryModel

    init(applicationModel: ApplicationModel) {
        let libraryModel = LibraryModel { release in
            return release.kind == .installer
        }
        _libraryModel = StateObject(wrappedValue: libraryModel)
        libraryModel.delegate = applicationModel
    }

    @ViewBuilder func withDeviceModel(@ViewBuilder content: (DeviceModel) -> some View) -> some View {
        if let deviceModel = applicationModel.devices.first {
            content(deviceModel)
                .environment(deviceModel)
                .focusedSceneObject(DeviceModelProxy(deviceModel: deviceModel))
        } else {
            EmptyView()
        }
    }

    var body: some View {

        NavigationSplitView {
            Sidebar()
        } detail: {
            switch navigationHistory.currentItem?.section {
            case .connecting:
                DisconnectedView()
            case .drive(let deviceId, let driveInfo):
                withDeviceModel { deviceModel in
                    DirectoryView(applicationModel: applicationModel,
                                  transfersModel: transfersModel,
                                  navigationHistory: navigationHistory,
                                  deviceModel: deviceModel,
                                  driveInfo: driveInfo,
                                  path: driveInfo.path)
                }
                .id("\(deviceId)\(driveInfo.path)")
            case .directory(let deviceId, let driveInfo, let path):
                withDeviceModel { deviceModel in
                    DirectoryView(applicationModel: applicationModel,
                                  transfersModel: transfersModel,
                                  navigationHistory: navigationHistory,
                                  deviceModel: deviceModel,
                                  driveInfo: driveInfo,
                                  path: path)
                }
                .id("\(deviceId)\(driveInfo.path)\(path)")
            case .device:
                withDeviceModel { _ in
                    DeviceView()
                }
            case .softwareIndex:
                ProgramsView()
                    .environmentObject(libraryModel)
            case .program(let program):
                ProgramView(program: program)
                    .environmentObject(libraryModel)
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
        .onChange(of: applicationModel.devices) { oldValue, newDevices in
            // When the set of available devices changes, we check to see if we need to update the UI accordingly.
            if let device = newDevices.first {
                // If we're currently displaying the connecting screen, then we want to instead display the new device.
                guard navigationHistory.currentItem?.section == .connecting else {
                    return
                }
                // When selecting the new device, we prefer the internal RAM drive if available.
                let section: BrowserSection = if let drive = device.internalDrive {
                    BrowserSection.drive(device.id, drive)
                } else {
                    BrowserSection.device(device.id)
                }
                navigationHistory.navigate(section)
            } else {
                switch navigationHistory.currentItem?.section {
                case .connecting, .softwareIndex, .program:
                    break
                case .device, .directory, .drive, .none:
                    navigationHistory.navigate(.connecting)
                }
            }
        }
    }

}
