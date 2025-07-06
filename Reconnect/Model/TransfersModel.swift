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
                               callback: @escaping (UInt32, UInt32) -> FileServer.ProgressResponse) async throws -> Transfer.FileDetails {

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
        // TODO: Perhaps implement this as a conflict handler?
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

    func download(from source: FileServer.DirectoryEntry,
                  to destinationURL: URL,
                  convertFiles: Bool) async throws -> URL {
        precondition(destinationURL.hasDirectoryPath)

        let download = Transfer(item: .remote(source)) { transfer in

            // Check to see if we're downloading a single file or a directory.
            if source.isDirectory {
                let fileManager = FileManager.default
                let targetURL = destinationURL.appendingPathComponent(source.path.lastWindowsPathComponent)
                let parentPath = source.path
                    .deletingLastWindowsPathComponent
                    .ensuringTrailingWindowsPathSeparator(isPresent: true)

                // Ensure the matching destination directory exists.
                try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)

                // Set the initial progress.
                let progress = Progress()
                transfer.setStatus(.active(progress))

                // Determine the number of items we need to process and update the process object.
                let files = try await self.fileServer.dir(path: source.path, recursive: true)
                progress.totalUnitCount = Int64(files.count)
                progress.fileTotalCount = files.count
                transfer.setStatus(.active(progress))

                // Iterate over the recursive directory listing creating directories and downloading files.
                var totalSize: UInt64 = 0

                // Create the directories.
                for file in files.filter({ $0.isDirectory }) {
                    print(file.path)
                    let relativePath = String(file.path.dropFirst(parentPath.count))
                    let innerDestinationURL = destinationURL
                        .appendingPathComponents(relativePath.windowsPathComponents)
                    let innerProgress = Progress()
                    innerProgress.kind = .file
                    innerProgress.setUserInfoObject(Progress.FileOperationKind.downloading, forKey: .fileOperationKindKey)
                    innerProgress.totalUnitCount = 1
                    progress.addChild(innerProgress, withPendingUnitCount: 1)
                    transfer.status = .active(progress)
                    try fileManager.createDirectory(at: innerDestinationURL, withIntermediateDirectories: true)
                    innerProgress.completedUnitCount = 1
                    transfer.status = .active(progress)
                }

                // Copy the files.
                for file in files.filter({ !$0.isDirectory }) {
                    let relativePath = String(file.path.dropFirst(parentPath.count))
                    let innerDestinationURL = destinationURL
                        .appendingPathComponents(relativePath.windowsPathComponents.dropLast())
                    let innerProgress = Progress()
                    innerProgress.kind = .file
                    innerProgress.setUserInfoObject(Progress.FileOperationKind.downloading, forKey: .fileOperationKindKey)
                    progress.addChild(innerProgress, withPendingUnitCount: 1)
                    let innerDetails = try await self._download(from: file,
                                                                to: innerDestinationURL,
                                                                convertFiles: convertFiles) { p, size in
                        innerProgress.totalUnitCount = Int64(size)
                        innerProgress.completedUnitCount = Int64(p)
                        transfer.setStatus(.active(progress))
                        return transfer.isCancelled ? .cancel : .continue
                    }
                    totalSize += innerDetails.size
                }

                let details: Transfer.FileDetails = .init(reference: .local(targetURL), size: totalSize)
                transfer.status = .complete(details)
                return details.reference
            } else {
                let progress = Progress()
                progress.kind = .file
                progress.setUserInfoObject(Progress.FileOperationKind.downloading, forKey: .fileOperationKindKey)
                transfer.setStatus(.active(progress))
                let details = try await self._download(from: source,
                                                       to: destinationURL,
                                                       convertFiles: convertFiles) { p, size in
                    progress.totalUnitCount = Int64(size)
                    progress.completedUnitCount = Int64(p)
                    transfer.setStatus(.active(progress))
                    return transfer.isCancelled ? .cancel : .continue
                }
                transfer.status = .complete(details)
                return details.reference
            }
        }

        // Append and run the transfer operation, waiting until it's complete.
        transfers.append(download)
        let reference = try await download.run()

        // Double check that we received a local file.
        guard case .local(let url) = reference else {
            throw ReconnectError.invalidFileReference
        }

        return url
    }

    func upload(from sourceURL: URL, to destinationPath: String) async throws {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
        let upload = Transfer(item: .local(sourceURL)) { transfer in
            try await self.fileServer.copyFile(fromLocalPath: sourceURL.path,
                                               toRemotePath: destinationPath) { progress, size in
                let p = Progress(totalUnitCount: Int64(size))
                p.completedUnitCount = Int64(progress)
                transfer.setStatus(.active(p))
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
