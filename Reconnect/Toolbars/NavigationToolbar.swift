// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2026 Jason Morley
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
    @Environment(NavigationHistory.self) private var navigationHistory

    @FocusedObject private var parentNavigable: ParentNavigableProxy?

    init() {
    }

    var body: some CustomizableToolbarContent {

        ToolbarItem(id: "navigation", placement: .navigation) {
            LabeledContent {
                HStack(spacing: 8) {

                    Menu {
                        ForEach(navigationHistory.previousItems) { item in
                            Button {
                                navigationHistory.navigate(item)
                            } label: {
                                SectionLabel(section: item.section)
                            }
                        }
                        .labelStyle(.titleAndIcon)
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    } primaryAction: {
                        navigationHistory.back()
                    }
                    .menuIndicator(.hidden)
                    .disabled(!navigationHistory.canGoBack())
                    .id(navigationHistory.generation)

                    Menu {
                        ForEach(navigationHistory.nextItems) { item in
                            Button {
                                navigationHistory.navigate(item)
                            } label: {
                                SectionLabel(section: item.section)
                            }
                        }
                        .labelStyle(.titleAndIcon)
                    } label: {
                        Label("Forward", systemImage: "chevron.forward")
                    } primaryAction: {
                        navigationHistory.forward()
                    }
                    .menuIndicator(.hidden)
                    .disabled(!navigationHistory.canGoForward())
                    .id(navigationHistory.generation)

                }
                .help("See folders you viewed previously")

            } label: {
                Text("Back/Forward")
            }

        }

        ToolbarItem(id: "open-enclosing-folder", placement: .navigation) {
            Button {
                parentNavigable?.navigateToParent()
            } label: {
                Label("Enclosing Folder", systemImage: "arrow.turn.left.up")
            }
            .disabled(!(parentNavigable?.canNavigateToParent ?? false))
        }

    }

}
