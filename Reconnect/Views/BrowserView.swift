// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024 Jason Morley
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

    @Environment(ApplicationModel.self) var applicationModel
    
    @State private var browserModel: BrowserModel

    init(fileServer: FileServer) {
        _browserModel = State(initialValue: BrowserModel(fileServer: fileServer))
    }

    var body: some View {
        NavigationSplitView {
            Sidebar(model: browserModel)
        } detail: {
            if applicationModel.isConnected {
                BrowserDetailView(browserModel: browserModel)
            } else {
                ContentUnavailableView("Disconnected", image: "Disconnected")
            }
        }
        .toolbar(id: "main") {
            ToolbarItem(id: "navigation", placement: .navigation) {
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
                    .disabled(!browserModel.canGoBack())

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
                    .disabled(!browserModel.canGoForward())

                }
                .help("See folders you viewed previously")
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
                    browserModel.download()
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
                        browserModel.download()
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

            ToolbarItem(id: "transfers") {
                TransfersPopoverButton(transfers: browserModel.transfersModel)
            }

            ToolbarItem(id: "refresh") {
                Button {
                    browserModel.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
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
        .environment(browserModel)
    }

}
