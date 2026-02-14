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

struct InstallQueryInstallerPage: View {

    @State var selection: DeviceModel.ID?

    private let applicationModel: ApplicationModel
    private let installQuery: InstallerModel.InstallQuery

    init(applicationModel: ApplicationModel, installQuery: InstallerModel.InstallQuery) {
        self.applicationModel = applicationModel
        self.installQuery = installQuery
        _selection = State(initialValue: applicationModel.devices.first(where: {$0.platform == installQuery.sis.target })?.id)
    }

    func updateSelection() {
        // Don't make any changes if the currently selected device is still available.
        guard !applicationModel.devices.contains(where: { $0.id == selection }) else {
            return
        }
        selection = applicationModel.devices.first(where: {$0.platform == installQuery.sis.target })?.id
    }

    var body: some View {
        WizardPage {
            VStack {

                VStack {
                    Image("Installer")
                        .padding(.bottom)
                    Text(installQuery.sis.localizedDisplayName)
                        .font(.title)
                    if installQuery.sis.version != .zero {
                        Text(installQuery.sis.version.description)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    if installQuery.sis.uid != 0 {
                        Text(String(format: "0x%08X", installQuery.sis.uid))
                            .foregroundStyle(.secondary)
                            .monospaced()
                    }
                    Text(installQuery.sis.target.localizedStringResource)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom)

                LabeledContent("Device") {
                    Menu {
                        ForEach(applicationModel.devices) { deviceModel in
                            Button {
                                selection = deviceModel.id
                            } label: {
                                Text(deviceModel.deviceConfiguration.name)
                            }
                            .disabled(deviceModel.platform != installQuery.sis.target)
                        }
                    } label: {
                        if let deviceModel = applicationModel.devices.first(where: { $0.id == selection }) {
                            Text(deviceModel.deviceConfiguration.name)
                        } else {
                            Text("No Compatible Devices")
                        }
                    }
                }
            }
        } actions: {
            Button("Cancel", role: .destructive) {
                installQuery.cancel()
            }
            Button("Continue") {
                guard let selection else {
                    return
                }
                installQuery.continue(deviceId: selection)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(selection == nil)
        }
        .onChange(of: applicationModel.devices) {
            updateSelection()
        }
    }

}
