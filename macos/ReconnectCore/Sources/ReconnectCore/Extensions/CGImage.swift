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

import CoreGraphics
import CoreImage

extension CGImage {

    /**
     * Generate a new CGImage by compositing grey and black planes. This conforms to the EPOC16 conventions for
     * PIC images (screenshots, etc), which are essentially multi-image MBMs with a black plane followed by a grey
     * plane.
     *
     * Internally, this validates that the two planes are of the same size and then uses them as masks to fill the
     * resulting image with grey, followed by black.
     *
     * Following the convention of many CoreGraphics APIs, this returns nil in the case of failure.
     */
    public static func composite(greyPlane: CGImage, blackPlane: CGImage) -> CGImage? {

        // Don't attempt to do anything if the two planes aren't the same size.
        guard blackPlane.width == greyPlane.width, blackPlane.height == greyPlane.height else {
            return nil
        }

        // Create the new context, and generate the inverted grey and black masks (as, alas, CoreGraphics has strong
        // opinions about how masks should be constructed).
        let rect = CGRect(x: 0, y: 0, width: blackPlane.width, height: blackPlane.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: Int(rect.size.width),
                                      height: Int(rect.size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let invertedGrey = greyPlane.inverted(),
              let invertedBlack = blackPlane.inverted()
        else {
            return nil
        }

        context.setFillColor(.white)
        context.fill(rect)

        context.preservingState { context in
            context.clip(to: rect, mask: invertedGrey)
            context.setFillColor(.grey)
            context.fill(rect)
        }
        context.preservingState { context in
            context.clip(to: rect, mask: invertedBlack)
            context.setFillColor(.black)
            context.fill(rect)
        }

        return context.makeImage()
    }

    public func inverted() -> CGImage? {
        let image = CIImage(cgImage: self)
        guard let filter = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            return nil
        }
        let context = CIContext()
        return context.createCGImage(outputImage, from: outputImage.extent)
    }

}
