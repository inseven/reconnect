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
import ReconnectCore
import Word2text

struct Conversion {

    let filename: (FileServer.DirectoryEntry) -> String
    let perform: (URL, URL) throws -> URL

}

extension Conversion {

    static let none: Self = Self { entry in
        return entry.name
    } perform: { sourceURL, destinationURL in
        return sourceURL
    }

    static let mbmConversion: Self = Self { entry in
        return entry.name.replacingPathExtension("tiff")
    } perform: { sourceURL, destinationURL in
        let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                              conformingTo: .tiff)
        try PsiLuaEnv().convertMultiBitmap(sourceURL: sourceURL, destinationURL: outputURL)
        try FileManager.default.removeItem(at: sourceURL)
        return outputURL
    }

    static let wordConversion: Self = Self { entry in
        return entry.name.replacingPathExtension("txt")
    } perform: { sourceURL, destinationURL in
        let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                              conformingTo: .plainText)
        let data = try Data(contentsOf: sourceURL)
        let output = try PsionWord.processFile(data).get()
        try output.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }

    static let textConversion: Self = Self { entry in
        return entry.name
    } perform: { sourceURL, destinationURL in
        let data = try Data(contentsOf: sourceURL)
        guard let contents = String(data: data, encoding: .ascii) else {
            throw ReconnectError.unknown
        }
        let output = contents.replacingOccurrences(of: "\r\n", with: "\n")
        try output.write(to: sourceURL, atomically: true, encoding: .utf8)
        return sourceURL
    }

    static let picConversion: Self = Self { entry in
        return entry.name.replacingPathExtension("png")
    } perform: { sourceURL, destinationURL in
        let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                              conformingTo: .png)
        let bitmaps = PsiLuaEnv().getMbmBitmaps(path: sourceURL.path) ?? []
        let images = bitmaps.map { bitmap in
            return CGImage.from(bitmap: bitmap)
        }

        guard
            images.count == 2,
            let image = CGImage.composite(greyPlane: images[1], blackPlane: images[0])
        else {
            throw ReconnectError.unknown
        }
        try CGImageWrite(destinationURL: outputURL, images: [image], type: .png)
        return outputURL
    }

}
