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

public struct NavigationCommands: Commands {

    @Environment(NavigationHistory.self) private var navigationHistory

    @FocusedObject private var parentNavigableProxy: ParentNavigableProxy?

    public var body: some Commands {

        CommandMenu("Go") {

            Button {
                navigationHistory.back()
            } label: {
                Label("Back", systemImage: "chevron.backward")
            }
            .keyboardShortcut("[", modifiers: [.command])
            .disabled(!navigationHistory.canGoBack())

            Button {
                navigationHistory.forward()
            } label: {
                Label("Forward", systemImage: "chevron.forward")
            }
            .keyboardShortcut("]", modifiers: [.command])
            .disabled(!navigationHistory.canGoForward())

            Button {
                parentNavigableProxy?.navigateToParent()
            } label: {
                Label("Enclosing Folder", systemImage: "arrow.turn.left.up")
            }
            .keyboardShortcut(.upArrow, modifiers: [.command])
            .disabled(!(parentNavigableProxy?.canNavigateToParent ?? false))
        }

    }

}
