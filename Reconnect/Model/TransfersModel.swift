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

    func download(from source: FileServer.DirectoryEntry, to destinationURL: URL? = nil, convertFiles: Bool) {
        let fileManager = FileManager.default
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let filename = source.path.lastWindowsPathComponent
        let downloadURL = destinationURL ?? downloadsURL.appendingPathComponent(filename)
        print("Downloading file at path '\(source.path)' to destination path '\(downloadURL.path)'...")

        transfers.append(Transfer(item: .remote(source)) { transfer in

            // Get the file information.
            let directoryEntry = try await self.fileServer.getExtendedAttributes(path: source.path)

            // Perform the file copy.
            try await self.fileServer.copyFile(fromRemotePath: source.path, toLocalPath: downloadURL.path) { progress, size in
                transfer.setStatus(.active(Float(progress) / Float(size)))
                return transfer.isCancelled ? .cancel : .continue
            }

            // Convert known types.
            // N.B. This would be better implemented as a user-configurable and extensible pipeline, but this is a
            // reasonable point to hook an initial implementation.
            var urls: [URL] = [downloadURL]
            if convertFiles {
                if directoryEntry.fileType == .mbm || directoryEntry.pathExtension.lowercased() == "mbm" {
                    urls = try PsiLuaEnv().convertMultiBitmap(at: downloadURL, removeSource: true)
                }
            }

            // Mark the transfer as complete.
            transfer.setStatus(.complete(urls.first))
        })
    }

    func upload(from sourceURL: URL, to destinationPath: String) {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
            transfers.append(Transfer(item: .local(sourceURL)) { transfer in
            try await self.fileServer.copyFile(fromLocalPath: sourceURL.path, toRemotePath: destinationPath) { progress, size in
                transfer.setStatus(.active(Float(progress) / Float(size)))
                return transfer.isCancelled ? .cancel : .continue
            }
            transfer.setStatus(.complete(nil))
        })
    }
    
    func clear() {
        transfers.removeAll { !$0.isActive }
    }

}

extension TransfersModel {
    
    func addDemoData() {
        let remoteFile = FileServer.DirectoryEntry(path: "D:\\Screenshots\\Thoughts Splash Screen",
                                                   name: "Thoughts Splash Screen",
                                                   size: 203,
                                                   attributes: .normal,
                                                   modificationDate: .now,
                                                   uid1: .directFileStore,
                                                   uid2: .appDllDoc,
                                                   uid3: .sketch)
        let error = ReconnectError.rfsvError(.init(rawValue: -37))
        transfers.append(Transfer(item: .remote(remoteFile),
                                  status: .waiting))
        transfers.append(Transfer(item: .remote(remoteFile),
                                  status: .failed(error)))
        transfers.append(Transfer(item: .local(URL(fileURLWithPath: "/Users/jbmorley/Thoughts Screenshot.png")),
                                  status: .cancelled))
    }
    
}
