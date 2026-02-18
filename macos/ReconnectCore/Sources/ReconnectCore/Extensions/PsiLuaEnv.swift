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
import Foundation
import UniformTypeIdentifiers

import OpoLuaCore

extension PsiLuaEnv {

    // TODO: This should probably throw.
    public func imagesFromMultiBitmap(at url: URL) -> [CGImage] {
        let bitmaps = getMbmBitmaps(path: url.path) ?? []
        let images = bitmaps.map { bitmap in
            return CGImage.from(bitmap: bitmap)
        }
        return images
    }

    public func convertMultiBitmap(sourceURL: URL, destinationURL: URL, type: UTType = .tiff) throws {
        let images = imagesFromMultiBitmap(at: sourceURL)
        try CGImageWrite(destinationURL: destinationURL, images: images, type: type)
    }

    public func convertPicToPNG(sourceURL: URL, destinationURL: URL) throws {
        let bitmaps = PsiLuaEnv().getMbmBitmaps(path: sourceURL.path) ?? []
        let images = bitmaps.map { bitmap in
            return CGImage.from(bitmap: bitmap)
        }
        guard
            images.count == 2,
            let image = CGImage.composite(greyPlane: images[1], blackPlane: images[0])
        else {
            throw ReconnectError.unknown  // TODO: FIX THIS ERROR.
        }
        try CGImageWrite(destinationURL: destinationURL, images: [image], type: .png)
    }

    public func loadSisFile(url: URL) throws -> Sis.File {
        let info = getFileInfo(path: url.path)
        guard case let .sis(sis) = info else {
            throw ReconnectError.invalidSisFile
        }
        return sis
    }

    public func loadSisFile(data: Data) throws -> Sis.File {
        let info = getFileInfo(data: data)
        guard case let .sis(sis) = info else {
            throw ReconnectError.invalidSisFile
        }
        return sis
    }

}
