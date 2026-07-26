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

/**
 * Fixed size image that loads its content asynchronously from a URL.
 *
 * There is no way this view should need to exist---it is entirely a side effect of bugs in SwiftUI on macOS whereby
 * `Image` will not respect `resizable` or `frame` modifiers when used in a menu.
 */
struct FixedSizeAsyncImage<Placeholder: View>: View {

    @Environment(\.displayScale) var displayScale

    @MainActor @State var nsImage: NSImage? = nil

    let url: URL
    let size: CGSize
    let placeholder: Placeholder

    init(url: URL, size: CGSize, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.size = size
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let nsImage {
                Image(nsImage: nsImage)
            } else {
                placeholder
            }
        }
        .task {
            guard
                let (data, _) = try? await URLSession.shared.data(from: url),
                let nsImage = NSImage(data: data)
            else {
                return
            }
            self.nsImage = nsImage.resized(size: size, scale: displayScale)
        }
    }

}
