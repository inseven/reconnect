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

// TODO: Rename to content view??
@MainActor
struct BrowserView: View {

    @Environment(\.openWindow) private var openWindow

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(TransfersModel.self) private var transfersModel
    @Environment(NavigationModel.self) private var navigationModel

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

        NavigationSplitView {
            Sidebar()
        } detail: {
            switch navigationModel.currentItem?.section {
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
            case .backupSet(let id, let name):
                VStack {
                    Text(name)
                    Text(id.uuidString)
                }
            case .backup(let backup):
                BackupSummaryView(backup: backup)
            case .none:
                Text("Nothing selected!")
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
        .frame(minWidth: 800, minHeight: 600)
    }

}

// Table: TabularDetailsSection?
struct TabularDetailsSection<Content: View, Label: View>: View {

    let content: Content
    let label: Label

    init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.content = content()
        self.label = label()
    }

    var body: some View {
        DetailsGroup {  // TODO: Rename DetailsGroup to DetailsSection??
            Form {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            label
        }
    }

}

extension TabularDetailsSection where Label == Text {

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        }
    }

    @_disfavoredOverload
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        }
    }

}

struct BackupSummaryView: View {

    let backup: BackupsModel.Backup

    var body: some View {
        InformationView {

            TabularDetailsSection("Device") {
                LabeledContent("Name:", value: backup.manifest.device.name)
                LabeledContent("Sync Identiifer:", value: backup.manifest.device.id.uuidString)
            }

            TabularDetailsSection("Summary") {
                LabeledContent {
                    Text(backup.manifest.date, format: .dateTime)
                } label: {
                    Text("Date:")
                }
            }

            HStack {
                Spacer()
                Button("Show in Finder") {
                    NSWorkspace.shared.open(backup.url)
                }
            }

        }
        .navigationTitle("Backup")
    }

}
