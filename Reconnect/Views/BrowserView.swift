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

struct TransferRow: View {

    let transfer: Transfer

    var body: some View {
        VStack(alignment: .leading) {
            Text(transfer.title)
            ProgressView(value: transfer.progress)
        }
        .padding()
    }

}

struct TransfersButton: View {

    let transfers: Transfers

    @State var showPopover = false

    var body: some View {
        @Bindable var transfers = transfers
        Button {
            showPopover = true
        } label: {
            Label {
                Text("Transfers")
            } icon: {
                if transfers.active {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .disabled(transfers.transfers.isEmpty)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                Text("Transfers")
                    .padding()
                Divider()
                List(selection: $transfers.selection) {
                    ForEach(transfers.transfers) { transfer in
                        TransferRow(transfer: transfer)
                    }
                }
                .scrollContentBackground(.hidden)
                .frame(minHeight: 300)
            }
            .frame(minWidth: 400)
            .background(.thinMaterial)
        }
    }

}

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
                ContentUnavailableView("Not Connected", systemImage: "star")
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

            ToolbarItem(id: "transfers") {
                TransfersButton(transfers: model.transfers)
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
