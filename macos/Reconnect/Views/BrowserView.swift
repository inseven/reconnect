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

@MainActor
struct BrowserView: View {

    @Environment(\.openWindow) private var openWindow

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(BackupsModel.self) private var backupsModel
    @Environment(TransfersModel.self) private var transfersModel
    @Environment(NavigationModel<BrowserSection>.self) private var navigationModel

    @ObservedObject private var libraryModel: LibraryModel

    init(libraryModel: LibraryModel) {
        _libraryModel = ObservedObject(wrappedValue: libraryModel)
    }

    @ViewBuilder func withDeviceModel(@ViewBuilder content: (DeviceModel) -> some View) -> some View {
        if let deviceModel = applicationModel.devices.first {
            content(deviceModel)
                .environment(deviceModel)
                .focusedSceneObject(DeviceModelProxy(deviceModel: deviceModel))
        } else {
            Text("No device found.")
        }
    }

    var body: some View {
        @Bindable var backupsModel = backupsModel

        NavigationSplitView {
            Sidebar()
        } detail: {
            switch navigationModel.current {
            case .disconnected:
                DisconnectedView()
            case .drive(let deviceId, let driveInfo, _):
                withDeviceModel { deviceModel in
                    DirectoryView(applicationModel: applicationModel,
                                  transfersModel: transfersModel,
                                  navigationModel: navigationModel,
                                  deviceModel: deviceModel,
                                  driveInfo: driveInfo,
                                  path: driveInfo.path)
                }
                .id("\(deviceId)\(driveInfo.path)")
            case .directory(let deviceId, let driveInfo, let path):
                withDeviceModel { deviceModel in
                    DirectoryView(applicationModel: applicationModel,
                                  transfersModel: transfersModel,
                                  navigationModel: navigationModel,
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
                ProgramView(navigationModel: navigationModel, program: program)
                    .environmentObject(libraryModel)
            case .backupSet(let device):
                BackupSetView(device: device)
            case .backup(let backup):
                BackupSummaryView(backup: backup)
            }
        }
        .toolbar(id: "main") {
            NavigationToolbar()
            DeviceToolbar()
            ToolbarSpacer(id: "spacer-1")
            FileToolbar()
            ToolbarSpacer(id: "spacer-2")
            RefreshToolbar()
        }
        .prompt(item: $backupsModel.prompt) { prompt in
            switch prompt {
            case .delete(let deleteConfirmation):
                Prompt("Delete Backup") {
                    Button("Delete", role: .destructive) {
                        deleteConfirmation.perform()
                    }
                } message: {
                    Text("Are you sure you want to delete this backup?")
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

}
