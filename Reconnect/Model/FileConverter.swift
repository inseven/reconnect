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

// This is expected to grow into some kind of engine / model for managing file conversions and giving in the moment
// answers about conversions based on the users choices and enabled conversions.
class FileConverter {

    private struct Conversion {
        let matches: (FileServer.DirectoryEntry) -> Bool
        let filename: (FileServer.DirectoryEntry) -> String
        let perform: (URL, URL) throws -> URL
    }

    static let convertFiles: (FileServer.DirectoryEntry, URL) throws -> URL = { entry, url in
        guard let converter = converter(for: entry) else {
            return url
        }
        return try converter.perform(url, url.deletingLastPathComponent())
    }

    static let identity: (FileServer.DirectoryEntry, URL) throws -> URL = { entry, url in
        return url
    }

    private static let converters: [Conversion] = [

        // MBM
        Conversion { entry in
            return entry.fileType == .mbm || entry.pathExtension.lowercased() == "mbm"
        } filename: { entry in
            return entry.name
                .deletingPathExtension
                .appendingPathExtension("tiff")
        } perform: { sourceURL, destinationURL in
            let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                                  conformingTo: .tiff)
            try PsiLuaEnv().convertMultiBitmap(at: sourceURL, to: outputURL)
            try FileManager.default.removeItem(at: sourceURL)
            return outputURL
        },

        // WRD
        Conversion { entry in
            return entry.pathExtension.lowercased() == "wrd"
        } filename: { entry in
            return entry
                .name
                .deletingPathExtension
                .appendingPathExtension("txt")
        } perform: { sourceURL, destinationURL in
            let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                                  conformingTo: .plainText)
            let data = try Data(contentsOf: sourceURL)
            let bytes = [UInt8](data)[...]
            var settings = ProcessSettings()
            settings.doShowInfo = false
            settings.doReturnMarkdown = false
            settings.doIncludeHeader = false
            let result = PsionWord.processFile(bytes, "", .init())
            switch result {
            case .success(let output):
                try output.write(to: outputURL, atomically: true, encoding: .utf8)
                return outputURL
            case .failure(let error):
                throw error
            }
        }

    ]

    private static func converter(for directoryEntry: FileServer.DirectoryEntry) -> Conversion? {
        return converters.first {
            $0.matches(directoryEntry)
        }
    }

    static func targetFilename(for directoryEntry: FileServer.DirectoryEntry) -> String {
        return converter(for: directoryEntry)?.filename(directoryEntry) ?? directoryEntry.name
    }

}
