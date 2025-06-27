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
            ZStack {

                // We place hidden buttons under the browser view to allow us to add additional keyboard shortcuts that
                // aren't reflected in the menu command structure. Hopefully we can replace this with official SwiftUI
                // support at some point.
                Button {
                    browserModel.openSelection()
                } label: {
                    EmptyView()
                }
                .keyboardShortcut(.downArrow, modifiers: [.command])

                BrowserDetailView(browserModel: browserModel)
            }
        }
        .toolbar(id: "main") {

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

            ToolbarItem(id: "new-folder") {
                Button {
                    browserModel.newFolder()
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }

            ToolbarItem(id: "download") {
                Button {
                    browserModel.download(to: FileManager.default.downloadsDirectory,
                                          convertFiles: applicationModel.convertFiles)
                } label: {
                    Label("New Folder", systemImage: "square.and.arrow.down")
                }
                .disabled(browserModel.isSelectionEmpty)
            }

            ToolbarItem(id: "delete") {
                Button {
                    browserModel.delete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(browserModel.isSelectionEmpty)
            }

            ToolbarItem(id: "action") {
                Menu {

                    Button("New Folder") {
                        browserModel.newFolder()
                    }

                    Divider()

                    Button("Download") {
                        browserModel.download(convertFiles: applicationModel.convertFiles)
                    }
                    .disabled(browserModel.isSelectionEmpty)

                    Divider()

                    Button("Delete") {
                        browserModel.delete()
                    }
                    .disabled(browserModel.isSelectionEmpty)

                } label: {
                    Label("Action", systemImage: "ellipsis.circle")
                }
            }

            ToolbarItem(id: "spacer") {
                Spacer()
            }

            ToolbarItem(id: "refresh") {
                Button {
                    browserModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            ToolbarItem(id: "spacer") {
                Spacer()
            }

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
