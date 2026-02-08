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

/**
 * Uses `NSImageView` under the hood to display a named image.
 *
 * This can be used to display animaged GIFs as, unlike `Image`, `NSImage` has this functionality built-in.
 */
struct ImageView: NSViewRepresentable {

    var name: String

    init(named name: String) {
        self.name = name
    }

    func makeNSView(context: Context) -> NSImageView {
        let image = NSImage(named: name)!
        return NSImageView(image: image)
    }

    func updateNSView(_ uiView: NSImageView, context: Context) {
    }

}
