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

struct BrowserDetailView: View {

    @State var isTargeted = false

    var model: BrowserModel

    var body: some View {
        @Bindable var model = model
        ZStack {
            Table(model.files, selection: $model.fileSelection) {
                TableColumn("") { file in
                    if file.isDirectory {
                        Image("Folder16")
                    } else {
                        switch file.uid3 {
                        case .word:
                            Image("Word16")
                        case .sheet:
                            Image("Sheet16")
                        case .record:
                            Image("Record16")
                        case .opl:
                            Image("OPL16")
                        case .data:
                            Image("Data16")
                        case .agenda:
                            Image("Agenda16")
                        case .sketch:
                            Image("Sketch16")
                        case .jotter:
                            Image("Jotter16")
                        default:
                            Image("FileUnknown16")
                        }
                    }
                }
                .width(16.0)
                TableColumn("Name", value: \.name)
                TableColumn("Date Modified") { file in
                    Text(file.modificationDate.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                TableColumn("Size") { file in
                    if file.isDirectory {
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
                .disabled(items.count != 1 || !(items.first?.isWindowsDirectory ?? false))

                Divider()

                Button("Download") {
                    for item in items {
                        model.download(from: item)
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
                    item.isWindowsDirectory
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
            if isTargeted {
                Rectangle()
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else {
                        return
                    }
                    model.upload(url: url)
                }
            }
            return true
        }
    }

}
