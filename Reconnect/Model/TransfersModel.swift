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

import SwiftUI

import ReconnectCore

@MainActor @Observable
class TransfersModel {

    var isActive: Bool {
        return transfers
            .map { $0.isActive }
            .reduce(false) { $0 || $1 }
    }

    var transfers: [Transfer] = []
    var selection: UUID? = nil

    let fileServer = FileServer()

    init() {
    }

    // Downloads and converts a single file. Fails if it's a directory entry.
    // destinationURL _must_ be a directory and must exist. To avoid collisions, if a temporary directory is used, it
    // should not be the top-level OS-provided temporary directory and should ideally be cleaned up after use.
    fileprivate func _download(from source: FileServer.DirectoryEntry,
                               to destinationURL: URL,
                               convertFiles: Bool,
                               callback: @escaping (UInt32, UInt32) -> FileServer.ProgressResponse) async throws -> Transfer.FileDetails {  // TODO: Plural?

        let fileManager = FileManager.default

        // Perform the file copy.
        let transferURL = fileManager.temporaryURL()
        try await self.fileServer.copyFile(fromRemotePath: source.path,
                                           toLocalPath: transferURL.path,
                                           callback: callback)

        // Convert the file if necessary.
        // Convert known types.
        // N.B. This would be better implemented as a user-configurable and extensible pipeline, but this is a
        // reasonable point to hook an initial implementation.
        // Get the file converter if necessary.
        let converter: FileConverter.Conversion? = convertFiles ? FileConverter.converter(for: source) : nil
        let conversionURL: URL = if let converter {
            try converter.perform(transferURL, fileManager.temporaryURL())
        } else {
            transferURL
        }
        print("Conversion url \(conversionURL)")

        // Move the completed file to the destination.
        // TODO: Move as v2 if it exists.
        // Numbering move?
        let filename = converter?.filename(source) ?? source.name
        let finalURL = destinationURL.appendingPathComponent(filename)
        try fileManager.moveItem(at: conversionURL, to: finalURL)
        print("Successfully moved from \(conversionURL) to \(finalURL)")

        // Get the final details.
        let size = try fileManager.attributesOfItem(atPath: finalURL.path)[.size] as! UInt64
        let details = Transfer.FileDetails(reference: .local(finalURL), size: size)
        return details
    }

    // TODO: Some form of completion block based decisions and progress?
    func download(from source: FileServer.DirectoryEntry,
                  to destinationURL: URL,
                  convertFiles: Bool) async throws -> URL {
        precondition(destinationURL.hasDirectoryPath)
        print("Downloading file '\(source.path)' to '\(destinationURL.path)'...")

        let download = Transfer(item: .remote(source)) { transfer in

            // Perform the transfer updating the progress as we do so.
            // This inner implementation takes responsibility of downloading to a temporary location and automatically
            // converting files for us. Future implementations should allow for an inline interactive conversion prompt.
            let details = try await self._download(from: source,
                                                    to: destinationURL,
                                                    convertFiles: convertFiles) { progress, size in
                transfer.setStatus(.active(progress, size))
                return transfer.isCancelled ? .cancel : .continue
            }

            // Mark the transfer as complete.
            transfer.status = .complete(details)

            // Report the result.
            return details.reference
        }

        // Append and run the transfer operation, waiting until it's complete.
        transfers.append(download)
        let reference = try await download.run()

        // Double check that we received a local file. This could perhaps be an assertion.
        guard case .local(let url) = reference else {
            throw ReconnectError.invalidFileReference
        }

        return url
    }

    func downloadDirectory(from path: String,
                           to downloadsURL: URL,
                           convertFiles: Bool) async throws -> URL {
        let fileManager = FileManager.default
        let targetURL = downloadsURL.appendingPathComponent(path.lastWindowsPathComponent)
        let parentPath = path.deletingLastWindowsPathComponent.ensuringTrailingWindowsPathSeparator(isPresent: true)

        // Here we know we're downloading a directory, so we make sure the destination exists.
        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)

        // Iterate over the recursive directory listing creating directories where necessary and downloading files.
        // TODO: We can use this to improve progress reporting by pre-creating Progress objects for it.
        let files = try await self.fileServer.dir(path: path, recursive: true)
        for file in files {
            let relativePath = String(file.path.dropFirst(parentPath.count))
            let destinationURL = downloadsURL.appendingPathComponents(relativePath.windowsPathComponents.dropLast())
            if file.isDirectory {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            } else {
                _ = try await self.download(from: file,
                                            to: destinationURL,
                                            convertFiles: convertFiles)
            }
        }
        return targetURL
    }

    func upload(from sourceURL: URL, to destinationPath: String) async throws {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
        let upload = Transfer(item: .local(sourceURL)) { transfer in
            try await self.fileServer.copyFile(fromLocalPath: sourceURL.path,
                                               toRemotePath: destinationPath) { progress, size in
                transfer.setStatus(.active(progress, size))
                return transfer.isCancelled ? .cancel : .continue
            }
            let directoryEntry = try await self.fileServer.getExtendedAttributes(path: destinationPath)
            let fileDetails = Transfer.FileDetails(reference: .remote(directoryEntry),
                                                   size: UInt64(directoryEntry.size))
            transfer.setStatus(.complete(fileDetails))
            return .remote(directoryEntry)
        }
        transfers.append(upload)
        _ = try await upload.run()
    }
    
    func clear() {
        transfers.removeAll { !$0.isActive }
    }

}
