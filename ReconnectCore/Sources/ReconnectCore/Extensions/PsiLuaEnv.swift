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

import CoreGraphics
import Foundation

import OpoLua

extension PsiLuaEnv {

    public func convertMultiBitmap(at url: URL, removeSource: Bool = false) throws {
        let directoryURL = (url as NSURL).deletingLastPathComponent!
        let basename = (url.lastPathComponent as NSString).deletingPathExtension
        let bitmaps = PsiLuaEnv().getMbmBitmaps(path: url.path) ?? []
        for (index, bitmap) in bitmaps.enumerated() {
            let identifier = if index < 1 {
                basename
            } else {
                "\(basename) \(index)"
            }
            let conversionURL = directoryURL
                .appendingPathComponent(identifier)
                .appendingPathExtension("png")
            let image = CGImage.from(bitmap: bitmap)
            try CGImageWritePNG(image, to: conversionURL)
        }
        if removeSource {
            try FileManager.default.removeItem(at: url)
        }
    }

}
