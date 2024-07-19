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

import ReconnectCore

struct BrowserDetailView: View {

    @Environment(ApplicationModel.self) var applicationModel

    @State var isTargeted = false

    var browserModel: BrowserModel

    var body: some View {
        @Bindable var browserModel = browserModel
        ZStack {
            Table(browserModel.files, selection: $browserModel.fileSelection) {
                TableColumn("") { file in
                    Image(file.fileType.image)
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

                TableColumn("Type") { file in
                    FileTypePopover(file: file)
                        .foregroundStyle(.secondary)
                }
            }
            .contextMenu(forSelectionType: FileServer.DirectoryEntry.ID.self) { items in

                Button("Open") {
                    browserModel.navigate(to: items.first!)
                }
                .disabled(items.count != 1 || !(items.first?.isWindowsDirectory ?? false))

                Divider()

                Button("Download") {
                    browserModel.download(items, convertFiles: applicationModel.convertFiles)
                }

                Divider()

                Button("Delete") {
                    browserModel.delete(items)
                }

            } primaryAction: { items in
                guard
                    items.count == 1,
                    let item = items.first,
                    item.isWindowsDirectory
                else {
                    return
                }
                browserModel.navigate(to: item)
            }
            .onDeleteCommand {
                browserModel.delete()
            }
            .contextMenu {
                Button("New Folder") {
                    browserModel.newFolder()
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
                    browserModel.upload(url: url)
                }
            }
            return true
        }
    }

}
