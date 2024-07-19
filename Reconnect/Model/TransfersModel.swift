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

    func add(_ title: String, action: @escaping (Transfer) async throws -> Void) {
        transfers.append(Transfer(title: title, action: action))
    }

    func download(from sourcePath: String, to destinationURL: URL? = nil, convertFiles: Bool) {
        let fileManager = FileManager.default
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let filename = sourcePath.lastWindowsPathComponent
        let downloadURL = destinationURL ?? downloadsURL.appendingPathComponent(filename)
        print("Downloading file at path '\(sourcePath)' to destination path '\(downloadURL.path)'...")

        add(filename) { transfer in

            // Get the file information.
            let directoryEntry = try await self.fileServer.getExtendedAttributes(path: sourcePath)

            // Perform the file copy.
            try await self.fileServer.copyFile(fromRemotePath: sourcePath, toLocalPath: downloadURL.path) { progress, size in
                transfer.setStatus(.active(Float(progress) / Float(size)))
                return transfer.isCancelled ? .cancel : .continue
            }

            // Convert known types.
            // N.B. This would be better implemented as a user-configurable and extensible pipeline, but this is a
            // reasonable point to hook an initial implementation.
            if convertFiles {
                if directoryEntry.fileType == .mbm {
                    let directoryURL = (downloadURL as NSURL).deletingLastPathComponent!
                    let basename = (downloadURL.lastPathComponent as NSString).deletingPathExtension
                    let bitmaps = PsiLuaEnv().getMbmBitmaps(path: downloadURL.path) ?? []
                    for (index, bitmap) in bitmaps.enumerated() {
                        let identifier = if index < 1 {
                            basename
                        } else {
                            "\(basename) \(index)"
                        }
                        let conversionURL = directoryURL
                            .appendingPathComponent(identifier)
                            .appendingPathExtension("png")
                        let image = CGImage.from(bitmap: bitmap)
                        try CGImageWritePNG(image, to: conversionURL)
                    }
                    try fileManager.removeItem(at: downloadURL)
                }
            }

            // Mark the transfer as complete.
            transfer.setStatus(.complete)
        }
    }

    func upload(from sourceURL: URL, to destinationPath: String) {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
        add(sourceURL.lastPathComponent) { transfer in
            try await self.fileServer.copyFile(fromLocalPath: sourceURL.path, toRemotePath: destinationPath) { progress, size in
                transfer.setStatus(.active(Float(progress) / Float(size)))
                return transfer.isCancelled ? .cancel : .continue
            }
            transfer.setStatus(.complete)
        }
    }

}
