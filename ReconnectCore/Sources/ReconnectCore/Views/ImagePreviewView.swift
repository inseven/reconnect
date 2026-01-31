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

import OpoLuaCore

@Observable
class ImagePreviewViewModel {

    struct IdentifiableImage: Identifiable {
        let id = UUID()
        let cgImage: CGImage

        init(_ cgImage: CGImage) {
            self.cgImage = cgImage
        }

    }

    let url: URL
    var images: [IdentifiableImage] = []

    init(url: URL) {
        self.url = url
    }

    func start() {
        let bitmaps = PsiLuaEnv().getMbmBitmaps(path: url.path) ?? []
        let images = bitmaps.map { bitmap in
            return IdentifiableImage(CGImage.from(bitmap: bitmap))
        }
        DispatchQueue.main.async {
            self.images = images
        }
    }

}

public struct ImagePreviewView: View {

    @State var model: ImagePreviewViewModel

    public init(url: URL) {
        self._model = State(initialValue: ImagePreviewViewModel(url: url))
    }

    public var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(model.images) { image in
                    Image(image.cgImage, scale: 1.0, label: Text("Cheese"))
                }
            }
        }
        .onAppear {
            model.start()
        }
    }

}

#Preview("Single") {
    ImagePreviewView(url: Bundle.module.url(forResource: "PsionStyle", withExtension: nil)!)
}

#Preview("Multiple") {
    ImagePreviewView(url: Bundle.module.url(forResource: "Icons.mbm", withExtension: nil)!)
}
