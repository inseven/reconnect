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

enum FileType: String, Identifiable {

    var id: Self {
        return self
    }

    case mbm
    case word
    case text
    case markdown

}

extension FileType {

    var localizedDescription: LocalizedStringKey {
        switch self {
        case .mbm:
            return "Multiple Bitmap Image (.mbm)"
        case .word:
            return "EPOC16 Word (.wrd)"
        case .text:
            return "Text (.txt)"
        case .markdown:
            return "Markdown (.md)"
        }
    }

}

extension FileType {

    func matches(directoryEntry: FileServer.DirectoryEntry) -> Bool {
        switch self {
        case .mbm:
            return directoryEntry.fileType == .mbm || directoryEntry.pathExtension.lowercased() == "mbm"
        case .word:
            return directoryEntry.pathExtension.lowercased() == "wrd"
        case .text:
            return directoryEntry.pathExtension.lowercased() == "txt"
        case .markdown:
            return directoryEntry.pathExtension.lowercased() == "md"
        }
    }

}

enum ConversionIdentifier: String {

    case none
    case mbmToTiff
    case wordToText
    case windowsAsciiToUnixUnicode

}

extension ConversionIdentifier {

    fileprivate var conversion: Conversion {
        switch self {
        case .none:
            return .none
        case .mbmToTiff:
            return .mbmConversion
        case .wordToText:
            return .wordConversion
        case .windowsAsciiToUnixUnicode:
            return .textConversion
        }
    }

    // TODO: Move this into the conversion?
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .none:
            return "None"
        case .mbmToTiff:
            return "TIFF"
        case .wordToText:
            return "Text"
        case .windowsAsciiToUnixUnicode:
            return "UTF8 with Unix Line Endings"
        }
    }

}

fileprivate struct Conversion {
    let filename: (FileServer.DirectoryEntry) -> String
    let perform: (URL, URL) throws -> URL
}


extension Conversion {

    fileprivate static let none: Self = Self { entry in
        return entry.name
    } perform: { sourceURL, destinationURL in
        return sourceURL
    }

    fileprivate static let mbmConversion: Self = Self { entry in
        return entry.name
            .deletingPathExtension
            .appendingPathExtension("tiff")
    } perform: { sourceURL, destinationURL in
        let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                              conformingTo: .tiff)
        try PsiLuaEnv().convertMultiBitmap(at: sourceURL, to: outputURL)
        try FileManager.default.removeItem(at: sourceURL)
        return outputURL
    }

    fileprivate static let wordConversion: Self = Self { entry in
        return entry
            .name
            .deletingPathExtension
            .appendingPathExtension("txt")
    } perform: { sourceURL, destinationURL in
        let outputURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent.deletingPathExtension,
                                                              conformingTo: .plainText)
        let data = try Data(contentsOf: sourceURL)
        let output = try PsionWord.processFile(data).get()
        try output.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }

    fileprivate static let textConversion: Self = Self { entry in
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

}

// This is expected to grow into some kind of engine / model for managing file conversions and giving in the moment
// answers about conversions based on the users choices and enabled conversions.
class FileConverter {

    static let convertFiles: (FileServer.DirectoryEntry, URL) throws -> URL = { entry, url in
        guard let converter = converter(for: entry) else {
            return url
        }
        return try converter.perform(url, url.deletingLastPathComponent())
    }

    static let identity: (FileServer.DirectoryEntry, URL) throws -> URL = { entry, url in
        return url
    }

    static let converters: [FileType: ConversionIdentifier] = [
        .mbm: .mbmToTiff,
        .word: .wordToText,
        .text: .windowsAsciiToUnixUnicode,
        .markdown: .windowsAsciiToUnixUnicode,
    ]

    private static func converter(for directoryEntry: FileServer.DirectoryEntry) -> Conversion? {
        return converters.first {
            $0.key.matches(directoryEntry: directoryEntry)
        }?.value.conversion
    }

    static func targetFilename(for directoryEntry: FileServer.DirectoryEntry) -> String {
        return converter(for: directoryEntry)?.filename(directoryEntry) ?? directoryEntry.name
    }

}
