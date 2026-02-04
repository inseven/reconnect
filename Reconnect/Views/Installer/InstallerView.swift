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

@MainActor
struct InstallerView: View {

    @Environment(\.closeWindow) private var closeWindow
    @Environment(\.window) private var window

    @State var installerModel: InstallerModel

    init(applicationModel: ApplicationModel, url: URL) {
        _installerModel = State(initialValue: InstallerModel(applicationModel: applicationModel, url: url))
    }

    var body: some View {
        VStack(spacing: 0) {
            switch installerModel.page {
            case .loading:
                InstallerPage {
                    VStack {
                        ProgressView()
                    }
                } actions: {
                    Button("Continue") {}
                        .keyboardShortcut(.defaultAction)
                        .disabled(true)
                }
            case .ready:
                InstallerPage {
                    VStack {
                        Image("Installer")
                    }
                } actions: {
                    Button("Continue") {}
                        .keyboardShortcut(.defaultAction)
                        .disabled(true)
                }
            case .checkingInstalledPackages(let progress):
                InstallerPage {
                    VStack {
                        Text("Checking installed packages...")
                        ProgressView(value: progress)
                    }
                    .padding()
                    .frame(maxWidth: WizardLayoutMetrics.maximumContentWidth)
                } actions: {
                    Button("Cancel", role: .destructive) {}
                        .disabled(true)
                }
            case .operation(let operation, let progress):
                InstallerPage {
                    VStack {
                        switch operation.type {
                        case .write:
                            Text("Copying '\(operation.path)'...")
                        case .delete:
                            Text("Deleting '\(operation.path)'...")
                        case .mkdir:
                            Text("Creating directory '\(operation.path)'...")
                        default:
                            Text(operation.path)
                        }
                        ProgressAnimation("install")
                        ProgressView(value: progress.fractionCompleted)
                    }
                    .padding()
                    .frame(maxWidth: WizardLayoutMetrics.maximumContentWidth)
                } actions: {
                    Button("Cancel", role: .destructive) {}
                        .disabled(true)
                }
            case .complete:
                WizardCompletePage("Installation Complete")
            case .error(let error):
                WizardErrorPage(error: error)
            }
        }
        .sheet(item: $installerModel.query) { query in
            switch query {
            case .configuration(let configurationQuery):
                ConfigurationQueryInstallerPage(query: configurationQuery)
            case .replace(let replaceQuery):
                ReplaceQueryInstallerPage(query: replaceQuery)
            case .text(let textQuery):
                TextQueryInstallerPage(query: textQuery)
            }
        }
        .onChange(of: installerModel.sis) { oldValue, newValue in
            guard let newValue else {
                return
            }
            window.title = newValue.localizedDisplayNameAndVersion
        }
        .runs(installerModel)
    }

}
