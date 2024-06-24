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

struct HistoryItemView: View {

    var image: NSImage {
        let representation = NSWorkspace.shared.icon(for: .folder)
            .bestRepresentation(for: NSRect(origin: .zero, size: CGSize(width: 16, height: 16)),
                                context: nil,
                                hints: nil)!
        let image = NSImage(size: representation.size)
        image.addRepresentation(representation)
        return image
    }

    let item: NavigationStack.Item

    var body: some View {
        HStack {
            Image(nsImage: image)
            Text(item.path.windowsLastPathComponent)
        }
    }
}