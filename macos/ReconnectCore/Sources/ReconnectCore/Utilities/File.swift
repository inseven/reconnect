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
 * Managed file reference.
 *
 * This exists to make it easier to deal with passing files around the app (temporary or otherwise) and ensuring that
 * they're cleaned up where appropriate when finished with.
 */
public class File {

    public let url: URL

    private let temporaryDirectoryURL: URL?

    public init(copying url: URL, filename: String? = nil) throws {
        let fileManager = FileManager.default
        let filename = filename ?? url.lastPathComponent
        let temporaryDirectoryURL = try fileManager.createTemporaryDirectory()
        self.url = temporaryDirectoryURL.appendingPathComponent(filename)
        self.temporaryDirectoryURL = temporaryDirectoryURL
        try fileManager.copyItem(at: url, to: self.url)
    }

    public init(referencing url: URL) {
        self.url = url
        self.temporaryDirectoryURL = nil
    }

    deinit {
        if let temporaryDirectoryURL {
            let fileManager = FileManager.default
            if fileManager.fileExists(at: temporaryDirectoryURL) {
                try? fileManager.removeItem(at: temporaryDirectoryURL)
            }
        }
    }

}
