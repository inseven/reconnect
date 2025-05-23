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

import SwiftUI

import OpoLua

import ReconnectCore

// This is expected to grow into some kind of engine / model for managing file conversions and giving in the moment answers
// about conversions based on the users choices and enabled conversions.
// TODO: This could be a tuple of matching operations and conversion operations to make things a little easier to reason about.
class FileConverter {

    // TODO: Rename
    struct Conversion {
        let matches: (FileServer.DirectoryEntry) -> Bool
        let filename: (FileServer.DirectoryEntry) -> String
        let perform: (URL, URL) throws -> URL
    }

    static let converters: [Conversion] = [

        // MBM
        .init { directoryEntry in
            return directoryEntry.fileType == .mbm || directoryEntry.pathExtension.lowercased() == "mbm"
        } filename: { directoryEntry in
            return directoryEntry.name
                .deletingPathExtension
                .appendingPathExtension("tiff")!
        } perform: { sourceURL, destinationURL in
            // TODO: Generate a temporary file? Should this be done in the outer?
            try PsiLuaEnv().convertMultiBitmap(at: sourceURL, to: destinationURL)
            try FileManager.default.removeItem(at: sourceURL)
            return destinationURL  // TODO: this is uuuugly
        }

    ]

    static func converter(for directoryEntry: FileServer.DirectoryEntry) -> Conversion? {
        return converters.first {
            $0.matches(directoryEntry)
        }
    }

    static func targetFilename(for directoryEntry: FileServer.DirectoryEntry) -> String {
        return converter(for: directoryEntry)?.filename(directoryEntry) ?? directoryEntry.name
    }

}

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

    // TODO: Consider exposing the downlaod filenames here for drag-and-drop consistency.

    // TODO: Should the converter be injected or should this provide the filename proposal API?
    // TODO: Injecting the converter isn't great since we want to be able to let the user choose interactively if
    // possible.
    func download(from source: FileServer.DirectoryEntry,
                  to destinationURL: URL? = nil,
                  convertFiles: Bool) async throws -> URL {  // TODO: Plural?
        let fileManager = FileManager.default

        print("Downloading file '\(source.path)'...")

        let download = Transfer(item: .remote(source)) { transfer in

            // Get the files into an array.
            // For each file in the array. Ensure the destination directory exists. Transfer it.

            // TODO: Consider always downloading to a temporary directory and then moving out in the last step.

            // Iterate over the files:
            let destinationURL = try (destinationURL ?? fileManager.createTemporaryDirectory())
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
            throw ReconnectError.unknown // TODO
        }

        return url
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

extension TransfersModel {
    
    func addDemoData() {
//        let remoteFile = FileServer.DirectoryEntry(path: "D:\\Screenshots\\Thoughts Splash Screen",
//                                                   name: "Thoughts Splash Screen",
//                                                   size: 2938478,
//                                                   attributes: .normal,
//                                                   modificationDate: .now,
//                                                   uid1: .directFileStore,
//                                                   uid2: .appDllDoc,
//                                                   uid3: .sketch)
//        let localFile = URL(fileURLWithPath: "/Users/jbmorley/Thoughts Screenshot.png")
//        let error = ReconnectError.rfsvError(.init(rawValue: -37))
//        transfers.append(Transfer(item: .remote(remoteFile), status: .waiting))
//        transfers.append(Transfer(item: .remote(remoteFile), status: .failed(error)))
//        transfers.append(Transfer(item: .local(localFile), status: .cancelled))
//
//        var min: UInt32 = 0
//        transfers.append(Transfer(item: .remote(remoteFile)) { transfer in
//            while min < remoteFile.size {
//                try await Task.sleep(for: .milliseconds(1))
//                min += 100
//                transfer.setStatus(.active(min, remoteFile.size))
//            }
//            transfer.setStatus(.complete(Transfer.FileDetails(url: localFile, size: UInt64(remoteFile.size))))
//        })

    }
    
}
