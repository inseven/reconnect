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

    func download(from source: FileServer.DirectoryEntry,
                  to destinationURL: URL? = nil,
                  convertFiles: Bool) async throws {
        let fileManager = FileManager.default
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let filename = source.path.lastWindowsPathComponent
        let destinationURL = destinationURL ?? downloadsURL.appendingPathComponent(filename)
        let temporaryURL = fileManager.temporaryDirectory.appendingPathComponent((UUID().uuidString))
        print("Downloading file at path '\(source.path)' to destination path '\(destinationURL.path)'...")

        let download = Transfer(item: .remote(source)) { transfer in

            // Get the file information.
            let directoryEntry = try await self.fileServer.getExtendedAttributes(path: source.path)

            // Perform the file copy.
            try await self.fileServer.copyFile(fromRemotePath: source.path, toLocalPath: temporaryURL.path) { progress, size in
                transfer.setStatus(.active(progress, size))
                return transfer.isCancelled ? .cancel : .continue
            }

            // Move the completed file to the destination.
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)

            // Convert known types.
            // N.B. This would be better implemented as a user-configurable and extensible pipeline, but this is a
            // reasonable point to hook an initial implementation.
            var url: URL = destinationURL
            if convertFiles {
                if directoryEntry.fileType == .mbm || directoryEntry.pathExtension.lowercased() == "mbm" {
                    url = try PsiLuaEnv().convertMultiBitmap(at: destinationURL, removeSource: true)
                }
            }

            // Get the file details.
            let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as! UInt64
            let details = Transfer.FileDetails(url: url, size: size)

            // Mark the transfer as complete.
            transfer.setStatus(.complete(details))
        }
        transfers.append(download)
        try await download.run()
    }

    func upload(from sourceURL: URL, to destinationPath: String) async throws {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
        let upload = Transfer(item: .local(sourceURL)) { transfer in
            try await self.fileServer.copyFile(fromLocalPath: sourceURL.path, toRemotePath: destinationPath) { progress, size in
                transfer.setStatus(.active(progress, size))
                return transfer.isCancelled ? .cancel : .continue
            }
            transfer.setStatus(.complete(nil))
        }
        transfers.append(upload)
        try await upload.run()
    }
    
    func clear() {
        transfers.removeAll { !$0.isActive }
    }

}

extension TransfersModel {
    
    func addDemoData() {
        let remoteFile = FileServer.DirectoryEntry(path: "D:\\Screenshots\\Thoughts Splash Screen",
                                                   name: "Thoughts Splash Screen",
                                                   size: 2938478,
                                                   attributes: .normal,
                                                   modificationDate: .now,
                                                   uid1: .directFileStore,
                                                   uid2: .appDllDoc,
                                                   uid3: .sketch)
        let localFile = URL(fileURLWithPath: "/Users/jbmorley/Thoughts Screenshot.png")
        let error = ReconnectError.rfsvError(.init(rawValue: -37))
        transfers.append(Transfer(item: .remote(remoteFile), status: .waiting))
        transfers.append(Transfer(item: .remote(remoteFile), status: .failed(error)))
        transfers.append(Transfer(item: .local(localFile), status: .cancelled))

        var min: UInt32 = 0
        transfers.append(Transfer(item: .remote(remoteFile)) { transfer in
            while min < remoteFile.size {
                try await Task.sleep(for: .milliseconds(1))
                min += 100
                transfer.setStatus(.active(min, remoteFile.size))
            }
            transfer.setStatus(.complete(Transfer.FileDetails(url: localFile, size: UInt64(remoteFile.size))))
        })

    }
    
}
