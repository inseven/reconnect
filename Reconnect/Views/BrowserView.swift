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

    @State var model: BrowserModel

    init(fileServer: FileServer) {
        _model = State(initialValue: BrowserModel(fileServer: fileServer))
    }

    var body: some View {
        NavigationSplitView {
            Sidebar(model: model)
        } detail: {
            VStack {
                Table(model.files, selection: $model.fileSelection) {
                    TableColumn("") { file in
                        if file.attributes.contains(.directory) {
                            Image("Folder16")
                        } else {
                            Image("FileUnknown16")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16.0)
                        }
                    }
                    .width(16.0)
                    TableColumn("Name", value: \.name)
                    TableColumn("Date Modified") { file in
                        Text(file.modificationDate.formatted(date: .long, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    TableColumn("Size") { file in
                        if file.attributes.contains(.directory) {
                            Text("--")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(file.size.formatted(.byteCount(style: .file)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .contextMenu(forSelectionType: FileServer.DirectoryEntry.ID.self) { items in
                    Button("Open") {
                        model.navigate(to: items.first!)
                    }
                    .disabled(items.count != 1 || !(items.first?.isDirectory ?? false))

                    Divider()

                    Button("Download") {
                        for item in items {
                            // TODO: Directories?
                            model.download(path: item)
                        }
                    }

                    Divider()

                    Button("Delete") {
                        for item in items {
                            model.delete(path: item)
                        }
                    }
                } primaryAction: { items in
                    guard
                        items.count == 1,
                        let item = items.first,
                        item.isDirectory
                    else {
                        return
                    }
                    model.navigate(to: item)
                }
                .contextMenu {
                    Button("New Folder") {
                        model.newFolder()
                    }
                }
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

            ToolbarItem(id: "refresh") {
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            ToolbarItem(id: "action") {
                Menu {
                    Button("New Folder") {
                        model.newFolder()
                    }
                } label: {
                    Label("Action", systemImage: "ellipsis.circle")
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
