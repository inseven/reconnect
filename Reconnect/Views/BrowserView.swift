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

struct BrowserView: View {

    @State var model = BrowserModel()

    @State var selection: Int = 1

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Drives") {
                    Label {
                        Text("Internal (C:)")
                    } icon: {
                        Image(systemName: "internaldrive")
                    }
                    .tag(1)
                }
            }
        } detail: {
            VStack {
                switch model.state {
                case .loading:
                    Text("Loading...")
                case .ready(let files):
                    Table(files, selection: $model.selection) {
                        TableColumn("") { file in
                            if file.attributes.contains(.directory) {
                                let image = NSWorkspace.shared.icon(for: .folder)
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16.0)
                            } else {
                                Image("FileUnknown")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16.0)
                            }
                        }
                        .width(16.0)
                        TableColumn("Name", value: \.name)
                        TableColumn("Size") { file in
                            Text(String(file.size))
                        }
                    }
                    .contextMenu(forSelectionType: FileServer.DirectoryEntry.ID.self) { items in
                        Button("Hello, World!") {

                        }
                    } primaryAction: { items in
                        guard
                            items.count == 1,
                            let item = items.first
                        else {
                            return
                        }
                        print(item)
                        // TODO: Differentiate between files and items.
                        model.load(path: item)
                    }
                case .error(let error):
                    Text(String(describing: error))
                }
            }

        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    model.back()
                } label: {
                    Label("Back", systemImage: "chevron.backward")
                }
                .disabled(model.history.count < 2)
            }
            ToolbarItem(placement: .navigation) {
                Button {

                } label: {
                    Label("Back", systemImage: "chevron.forward")
                }
                .disabled(true)
            }
        }
        .onAppear {
            model.load(path: "C:\\")
        }
    }

}
