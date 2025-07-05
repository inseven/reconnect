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

struct NavigationToolbar: CustomizableToolbarContent {

    @Environment(ApplicationModel.self) private var applicationModel

    private var browserModel: BrowserModel

    init(browserModel: BrowserModel) {
        self.browserModel = browserModel
    }

    var body: some CustomizableToolbarContent {

        ToolbarItem(id: "open-enclosing-folder", placement: .navigation) {
            Button {
                browserModel.openEnclosingFolder()
            } label: {
                Label("Enclosing Folder", systemImage: "arrow.turn.left.up")
            }
            .disabled(!browserModel.canOpenEnclosingFolder)
        }

        ToolbarItem(id: "navigation", placement: .navigation) {
            LabeledContent {
                HStack(spacing: 8) {

                    Menu {
                        ForEach(browserModel.previousItems) { item in
                            Button {
                                browserModel.navigate(to: item)
                            } label: {
                                HistoryItemView(item: item)
                            }
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    } primaryAction: {
                        browserModel.back()
                    }
                    .menuIndicator(.hidden)
                    .disabled(!browserModel.canGoBack)

                    Menu {
                        ForEach(browserModel.nextItems) { item in
                            Button {
                                browserModel.navigate(to: item)
                            } label: {
                                HistoryItemView(item: item)
                            }
                        }
                    } label: {
                        Label("Forward", systemImage: "chevron.forward")
                    } primaryAction: {
                        browserModel.forward()
                    }
                    .menuIndicator(.hidden)
                    .disabled(!browserModel.canGoForward)

                }
                .help("See folders you viewed previously")

            } label: {
                Text("Back/Forward")
            }

        }

    }

}
