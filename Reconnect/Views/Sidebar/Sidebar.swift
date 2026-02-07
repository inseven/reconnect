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

struct Sidebar: NSViewRepresentable {

    @Environment(ApplicationModel.self) private var applicationModel
    @Environment(NavigationModel<BrowserSection>.self) private var navigationModel

    public final class Coordinator: NSObject, SidebarContainerViewDelegate {

        var parent: Sidebar

        init(_ parent: Sidebar) {
            self.parent = parent
        }

        func sidebarContainerView(_ sidebarContainerView: SidebarContainerView,
                                  didSelectSection section: BrowserSection) {
            parent.navigationModel.navigate(to: section)
        }

    }

    init() {
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeNSView(context: Context) -> SidebarContainerView {
        let sidebarContainerView = SidebarContainerView()
        sidebarContainerView.delegate = context.coordinator
        applicationModel.connectionDelegate = sidebarContainerView
        applicationModel.backupsModel.delegate = sidebarContainerView
        return sidebarContainerView
    }

    func updateNSView(_ sidebarContainerView: SidebarContainerView, context: Context) {
        sidebarContainerView.selectedSection = navigationModel.currentItem!.element
    }

}
