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

import Foundation

extension FileManager {

    public var downloadsDirectory: URL {
        return urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    public func temporaryURL(isDirectory: Bool = false) -> URL {
        return temporaryDirectory.appendingPathComponent((UUID().uuidString), isDirectory: isDirectory)
    }

    public func createTemporaryDirectory() throws -> URL {
        let temporaryURL = temporaryURL(isDirectory: true)
        try createDirectory(at: temporaryURL, withIntermediateDirectories: true)
        return temporaryURL
    }

    public func directoryExists(at url: URL) -> Bool {
        guard url.isFileURL else {
            return false
        }
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    public func fileExists(at url: URL) -> Bool {
        guard url.isFileURL else {
            return false
        }
        return fileExists(atPath: url.path)
    }

    public func removeItemLoggingErrors(at url: URL) throws {
        do {
            try removeItem(at: url)
        } catch {
            print("Failed to remove item at path '\(url.path)' with error '\(error)'.")
            throw error
        }
    }

    public func safelyMoveItem(at sourceURL: URL, toDirectory destinationDirectoryURL: URL) throws -> URL {
        let preferredURL = destinationDirectoryURL.appendingPathComponent(sourceURL.lastPathComponent)
        return try safelyMoveItem(at: sourceURL, toPreferredURL: preferredURL)
    }

    public func safelyMoveItem(at sourceURL: URL, toPreferredURL preferredURL: URL) throws -> URL {
        let basename = preferredURL.lastPathComponent.deletingPathExtension
        let ext = preferredURL.lastPathComponent.pathExtension
        for index in 1... {
            let filename = if index == 1 {
                ext.isEmpty ? basename : "\(basename).\(ext)"
            } else {
                ext.isEmpty ? "\(basename) \(index)" : "\(basename) \(index).\(ext)"
            }
            let destinationURL = preferredURL.deletingLastPathComponent().appendingPathComponent(filename)
            guard !fileExists(at: destinationURL) else {
                continue
            }
            try moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        }
        throw POSIXError(.EEXIST)
    }

}
