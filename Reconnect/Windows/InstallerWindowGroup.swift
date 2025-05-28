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

import Diligence

import UniformTypeIdentifiers
import os

struct RemovesTitle: ViewModifier {

    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content
                .toolbar(removing: .title)
        } else {
            content
        }
    }

}

extension View {

    func removesTitle() -> some View {
        return modifier(RemovesTitle())
    }

}

struct InstallerWindowGroup: Scene {

    struct LayoutMetrics {
        static let width: CGFloat = 800.0
        static let height: CGFloat = 600.0
    }

    var body: some Scene {
        DocumentGroup(viewing: InstallerDocument.self) { reference in
            // We use a document viewer to allow us to differentiate between file types in the future. Unfortunately,
            // this means we get the weird versioining drop-downs in the window toolbar/titlebar. So we disable that
            // where we can using the `removesTitle` modifier.
            InstallerView(installer: reference.document)
                .modifier(RemovesTitle())
                .navigationTitle("Install")
                .frame(width: LayoutMetrics.width, height: LayoutMetrics.height)
        }
        .windowResizability(.contentSize)
    }

}
