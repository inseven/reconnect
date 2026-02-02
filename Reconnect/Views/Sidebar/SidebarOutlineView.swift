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

// TODO: This could also just poke the AppDelegate directly??
struct SidebarOutlineView: NSViewRepresentable {

    @Environment(ApplicationModel.self) private var applicationModel

    public final class Coordinator: NSObject, SidebarOutlineViewContainerViewDelegate {

        var parent: SidebarOutlineView

        init(_ parent: SidebarOutlineView) {
            self.parent = parent
        }

        func sidebarOutlineVieContainer(_ sidebarOutlineVieContainer: SidebarOutlineViewContainerView,
                                        didSelecSection section: BrowserSection) {
            parent.applicationModel.navigate(to: section)
        }

    }

    init() {
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeNSView(context: Context) -> SidebarOutlineViewContainerView {
        let outlineContainerView = SidebarOutlineViewContainerView()
        outlineContainerView.delegate = context.coordinator
        applicationModel.delegate = outlineContainerView
        return outlineContainerView
    }

    func updateNSView(_ nsView: SidebarOutlineViewContainerView, context: Context) {
        // TODO: Update the selection here??
        // TODO: Does this get called when navigation history changes??
    }

}
