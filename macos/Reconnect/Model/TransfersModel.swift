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

    init() {
    }

    // Downloads and converts a single file. Fails if it's a directory entry.
    // destinationURL _must_ be a directory and must exist.
    // Accepts a `process` block which can be used to perform file conversions during processing.
    // TODO: Move this into `FileServer`
    fileprivate func downloadFile(using fileServer: FileServer,
                                  from source: FileServer.DirectoryEntry,
                                  to destinationURL: URL,
                                  process: (FileServer.DirectoryEntry, URL) throws -> URL,
                                  callback: @escaping (UInt32, UInt32) -> FileServer.ProgressResponse) async throws -> Transfer.FileDetails {

        let fileManager = FileManager.default
        let temporaryDirectory = try fileManager.createTemporaryDirectory()
        defer {
            try? fileManager.removeItemLoggingErrors(at: temporaryDirectory)
        }

        // Perform the file copy.
        let transferURL = temporaryDirectory.appendingPathComponent(source.path.lastWindowsPathComponent)
        try await fileServer.copyFile(fromRemotePath: source.path,
                                      toLocalPath: transferURL.path,
                                      callback: callback)
        let processedURL = try process(source, transferURL)

        // Move the completed file to the destination.
        let finalURL = destinationURL.appendingPathComponent(processedURL.lastPathComponent)
        try fileManager.moveItem(at: processedURL, to: finalURL)

        // Get the final details.
        let size = try fileManager.attributesOfItem(atPath: finalURL.path)[.size] as! UInt64
        let details = Transfer.FileDetails(reference: .local(finalURL), size: size)
        return details
    }

    func download(fileServer: FileServer,
                  sourceDirectoryEntry: FileServer.DirectoryEntry,
                  destinationURL: URL,
                  process: @escaping (FileServer.DirectoryEntry, URL) throws -> URL) async throws -> URL {
        precondition(destinationURL.hasDirectoryPath)

        let download = Transfer(item: .remote(sourceDirectoryEntry)) { transfer in

            // Check to see if we're downloading a single file or a directory.
            if sourceDirectoryEntry.isDirectory {
                let fileManager = FileManager.default
                let targetURL = destinationURL.appendingPathComponent(sourceDirectoryEntry.path.lastWindowsPathComponent)
                let parentPath = sourceDirectoryEntry.path
                    .deletingLastWindowsPathComponent
                    .ensuringTrailingWindowsPathSeparator(isPresent: true)

                // Ensure the matching destination directory exists.
                try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)

                // Set the initial progress.
                let progress = Progress()
                transfer.setStatus(.active(progress))

                // Determine the number of items we need to process and update the process object.
                let files = try await fileServer.dir(path: sourceDirectoryEntry.path, recursive: true)
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
                    let innerDetails = try await self.downloadFile(using: fileServer,
                                                                   from: file,
                                                                   to: innerDestinationURL,
                                                                   process: process) { p, size in
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
                let details = try await self.downloadFile(using: fileServer,
                                                          from: sourceDirectoryEntry,
                                                          to: destinationURL,
                                                          process: process) { p, size in
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

    func upload(fileServer: FileServer, sourceURL: URL, destinationPath: String) async throws {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
        let upload = Transfer(item: .local(sourceURL)) { transfer in
            try await fileServer.copyFile(fromLocalPath: sourceURL.path,
                                          toRemotePath: destinationPath) { progress, size in
                let p = Progress(totalUnitCount: Int64(size))
                p.completedUnitCount = Int64(progress)
                transfer.setStatus(.active(p))
                return transfer.isCancelled ? .cancel : .continue
            }
            let directoryEntry = try await fileServer.getExtendedAttributes(path: destinationPath)
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
