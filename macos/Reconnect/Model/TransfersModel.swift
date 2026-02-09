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

    let workQueue = DispatchQueue(label: "TransfersModel.workQueue")

    init() {
    }

    func newTransfer(fileReference: FileReference) -> Transfer {
        TransfersWindow.reveal()
        let transfer = Transfer(item: fileReference) { _ in
            // This block is part of a transition away from transfer blocks that perform the work, to simple tracking
            // objects. This means that this block will never be run so the throw is the cleanest situation to notice
            // if it's called by mistake.
            throw ReconnectError.unknown
        }
        DispatchQueue.main.async {
            self.transfers.append(transfer)
        }
        return transfer
    }

    func upload(fileServer: FileServer, sourceURL: URL, destinationPath: String) throws {
        print("Uploading file at path '\(sourceURL.path)' to destination path '\(destinationPath)'...")
        TransfersWindow.reveal()
        let upload = Transfer(item: .local(sourceURL)) { transfer in
            try fileServer.copyFile(fromLocalPath: sourceURL.path,
                                          toRemotePath: destinationPath) { progress, size in
                let p = Progress(totalUnitCount: Int64(size))
                p.completedUnitCount = Int64(progress)
                transfer.setStatus(.active(p))
                return transfer.isCancelled ? .cancel : .continue
            }
            let directoryEntry = try fileServer.getExtendedAttributesSync(path: destinationPath)
            let fileDetails = Transfer.FileDetails(reference: .remote(directoryEntry),
                                                   size: UInt64(directoryEntry.size))
            transfer.setStatus(.complete(fileDetails))
            return .remote(directoryEntry)
        }
        transfers.append(upload)
        workQueue.async {
            _ = try? upload.run()
        }
    }

    func clear() {
        transfers.removeAll { !$0.isActive }
    }

}
