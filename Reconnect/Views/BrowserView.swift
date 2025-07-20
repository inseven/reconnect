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

    private var browserModel: BrowserModel

    init(browserModel: BrowserModel) {
        self.browserModel = browserModel
    }

    var body: some View {

        @Bindable var browserModel = browserModel

        NavigationSplitView {
            Sidebar(model: browserModel)
        } detail: {
            BrowserDetailView(browserModel: browserModel)
        }
        .toolbar(id: "main") {

            StatusToolbar(applicationModel: applicationModel)

            NavigationToolbar(browserModel: browserModel)

            ToolsToolbar(browserModel: browserModel)
            ToolbarSpacer()
            FileToolbar(browserModel: browserModel)
            ToolbarSpacer()

            ToolbarItem(id: "add") {
                Menu {
                    Button("Install...") {
                        applicationModel.openInstaller()
                    }
                    Divider()
                    PsionSoftwareIndexLink()
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }

            ToolbarSpacer()
            BrowserToolbar(browserModel: browserModel)

        }
        .navigationTitle(browserModel.navigationTitle ?? "My Psion")
        .presents($browserModel.lastError)
        .onAppear {
            browserModel.navigate(to: "C:\\")
        }
        .task {
            await browserModel.start()
        }
    }

}
