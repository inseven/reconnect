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
    
    @State var model: BrowserModel

    init(fileServer: FileServer) {
        _model = State(initialValue: BrowserModel(fileServer: fileServer))
    }

    var body: some View {
        NavigationSplitView {
            Sidebar(model: model)
        } detail: {
            if applicationModel.isConnected {
                BrowserDetailView(model: model)
            } else {
                ContentUnavailableView("Disconnected", image: "Disconnected")
            }
        }
        .toolbar(id: "main") {
            ToolbarItem(id: "navigation", placement: .navigation) {
                HStack(spacing: 8) {

                    Menu {
                        ForEach(model.previousItems) { item in
                            Button {
                                model.navigate(to: item)
                            } label: {
                                HistoryItemView(item: item)
                            }
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    } primaryAction: {
                        model.back()
                    }
                    .menuIndicator(.hidden)
                    .disabled(!model.canGoBack())

                    Menu {
                        ForEach(model.nextItems) { item in
                            Button {
                                model.navigate(to: item)
                            } label: {
                                HistoryItemView(item: item)
                            }
                        }
                    } label: {
                        Label("Forward", systemImage: "chevron.forward")
                    } primaryAction: {
                        model.forward()
                    }
                    .menuIndicator(.hidden)
                    .disabled(!model.canGoForward())

                }
                .help("See folders you viewed previously")
            }

            ToolbarItem(id: "new-folder") {
                Button {
                    model.newFolder()
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }

            ToolbarItem(id: "delete") {
                Button {
                    model.delete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(!model.canDelete)
            }

            ToolbarItem(id: "action") {
                Menu {

                    Button("New Folder") {
                        model.newFolder()
                    }

                    Divider()

                    Button("Download") {
                        model.download()
                    }

                    Divider()

                    Button("Delete") {
                        model.delete()
                    }

                } label: {
                    Label("Action", systemImage: "ellipsis.circle")
                }
            }

            ToolbarItem(id: "spacer") {
                Spacer()
            }

            ToolbarItem(id: "transfers") {
                TransfersPopoverButton(transfers: model.transfersModel)
            }

            ToolbarItem(id: "refresh") {
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

        }
        .navigationTitle(model.navigationTitle ?? "My Psion")
        .presents($model.lastError)
        .onAppear {
            model.navigate(to: "C:\\")
        }
        .task {
            await model.start()
        }
        .environment(model)
    }

}
