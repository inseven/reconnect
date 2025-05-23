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

import Interact

struct PixelImage: View {

    enum Source {
        case name(String)
        case resource(ImageResource)
    }

    let source: Source

    init(_ name: String) {
        self.source = .name(name)
    }

    init(_ resource: ImageResource) {
        self.source = .resource(resource)
    }

    var image: Image {
        switch source {
        case .name(let string):
            Image(string)
        case .resource(let resource):
            Image(resource)
        }
    }

    var body: some View {
        image
            .interpolation(.none)
            .resizable()
    }

}
