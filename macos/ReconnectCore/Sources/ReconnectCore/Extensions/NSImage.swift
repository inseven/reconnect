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

extension NSImage {

    public func resized(size: NSSize, scale: CGFloat) -> NSImage? {
        if let representation = NSBitmapImageRep(bitmapDataPlanes: nil,
                                                 pixelsWide: Int(size.width * scale),
                                                 pixelsHigh: Int(size.height * scale),
                                                 bitsPerSample: 8,
                                                 samplesPerPixel: 4,
                                                 hasAlpha: true,
                                                 isPlanar: false,
                                                 colorSpaceName: .calibratedRGB,
                                                 bytesPerRow: 0,
                                                 bitsPerPixel: 0) {
            representation.size = size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
            draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                 from: .zero,
                 operation: .copy,
                 fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let image = NSImage(size: size)
            image.addRepresentation(representation)

            return image
        }

        return nil
    }

}
