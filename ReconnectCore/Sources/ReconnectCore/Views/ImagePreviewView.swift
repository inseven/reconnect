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

public struct ImagePreviewView: View {

    @State var model: ImagePreviewViewModel

    public init(url: URL) {
        self._model = State(initialValue: ImagePreviewViewModel(url: url))
    }

    public var body: some View {
        // This is a little gnarly: we use a geometry reader to determine the available width to so we can dynamically
        // decide whether to use nearest neighbor resizing if we're scaling up, or regular resizing otherwise. This
        // ensures images look crisp when displayed at the correct size, but don't get blocky when displayed at smaller
        // sizes.
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    ForEach(model.images) { image in
                        Image(image.cgImage, scale: 1.0, label: Text("Image"))
                            .interpolation(geometry.size.width >= CGFloat(image.cgImage.size.width) ? .none : .medium)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: CGFloat(image.cgImage.width), maxHeight: CGFloat(image.cgImage.height))
                    }
                }
            }
        }
        .onAppear {
            model.start()
        }
    }

}

#Preview("Single") {
    ImagePreviewView(url: Bundle.module.url(forResource: "PsionStyle.mbm", withExtension: nil)!)
}

#Preview("Single - Small") {
    ImagePreviewView(url: Bundle.module.url(forResource: "PsionStyle.mbm", withExtension: nil)!)
        .frame(width: 200, height: 200)
}

#Preview("Multiple") {
    ImagePreviewView(url: Bundle.module.url(forResource: "Icons.mbm", withExtension: nil)!)
}
