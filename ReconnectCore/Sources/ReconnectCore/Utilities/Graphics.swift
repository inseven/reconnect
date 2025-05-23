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

import Foundation
import ImageIO
import UniformTypeIdentifiers

public func CGImageWriteTIFF(destinationURL: URL, images: [CGImage]) throws  {
    guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                            UTType.tiff.identifier as CFString,
                                                            images.count,
                                                            nil) else {
        throw ReconnectError.imageSaveError
    }
    for image in images {
        CGImageDestinationAddImage(destination, image, nil)
    }
    guard CGImageDestinationFinalize(destination) else {
        throw ReconnectError.imageSaveError
    }
}
