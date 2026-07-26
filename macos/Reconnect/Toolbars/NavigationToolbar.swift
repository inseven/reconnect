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

import ReconnectCore

struct NavigationToolbar: CustomizableToolbarContent {

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(NavigationModel<BrowserSection>.self) private var navigationModel

    @FocusedObject private var parentNavigable: ParentNavigableProxy?

    init() {
    }

    var body: some CustomizableToolbarContent {

        ToolbarItem(id: "navigation", placement: .navigation) {
            ControlGroup {

                Menu {
                    ForEach(navigationModel.previousItems) { item in
                        Button {
                            navigationModel.navigate(to: item)
                        } label: {
                            SectionLabel(applicationModel: applicationModel, section: item.element)
                        }
                        .disabled(!navigationModel.canNavigate(to: item))
                    }
                    .labelStyle(.titleAndIcon)
                } label: {
                    Label("Back", systemImage: "chevron.backward")
                } primaryAction: {
                    navigationModel.back()
                }
                .menuIndicator(.hidden)
                .disabled(!navigationModel.canGoBack())
                .id(navigationModel.generation)

                Menu {
                    ForEach(navigationModel.nextItems) { item in
                        Button {
                            navigationModel.navigate(to: item)
                        } label: {
                            SectionLabel(applicationModel: applicationModel, section: item.element)
                        }
                        .disabled(!navigationModel.canNavigate(to: item))
                    }
                    .labelStyle(.titleAndIcon)
                } label: {
                    Label("Forward", systemImage: "chevron.forward")
                } primaryAction: {
                    navigationModel.forward()
                }
                .menuIndicator(.hidden)
                .disabled(!navigationModel.canGoForward())
                .id(navigationModel.generation)

            } label: {
                Text("Back/Forward")
            }
            .controlGroupStyle(.navigation)
            .help("See items you viewed previously")

        }

        ToolbarItem(id: "open-enclosing-folder", placement: .navigation) {
            Button {
                parentNavigable?.navigateToParent()
            } label: {
                Label("Enclosing Folder", systemImage: "arrow.turn.left.up")
            }
            .help("Navigate to this view's parent")
            .disabled(!(parentNavigable?.canNavigateToParent ?? false))
        }

    }

}
