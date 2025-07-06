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

struct FileToolbar: CustomizableToolbarContent {

    @Environment(ApplicationModel.self) private var applicationModel

    private var browserModel: BrowserModel

    init(browserModel: BrowserModel) {
        self.browserModel = browserModel
    }

    var body: some CustomizableToolbarContent {

        ToolbarItem(id: "new-folder") {
            Button {
                browserModel.newFolder()
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
            }
        }

        ToolbarItem(id: "download") {
            Button {
                browserModel.download(to: applicationModel.downloadsURL,
                                      convertFiles: applicationModel.convertFiles,
                                      completion: { _ in })
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
                    browserModel.download(to: applicationModel.downloadsURL,
                                          convertFiles: applicationModel.convertFiles,
                                          completion: { _ in })
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

    }

}
