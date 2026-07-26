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

@Observable
class Transfer: Identifiable, @unchecked Sendable {

    struct FileDetails: Equatable {
        let reference: FileReference
        let size: UInt64

        init(reference: FileReference, size: UInt64 = 0) {
            self.reference = reference
            self.size = size
        }

        init(localURL: URL, size: UInt64 = 0) {
            self.reference = .local(localURL)
            self.size = size
        }

        init(remoteDirectoryEntry: FileServer.DirectoryEntry, size: UInt64 = 0) {
            self.reference = .remote(remoteDirectoryEntry)
            self.size = size
        }

    }

    enum Status: Equatable {

        static func == (lhs: Transfer.Status, rhs: Transfer.Status) -> Bool {
            switch lhs {
            case .waiting:
                if case .waiting = rhs {
                    return true
                }
                return false
            case .active(let lhsProgress):
                if case let .active(rhsProgress) = rhs {
                    return lhsProgress == rhsProgress
                }
                return false
            case .complete(let lhsDetails):
                if case let .complete(rhsDetails) = rhs {
                    return lhsDetails == rhsDetails
                }
                return false
            case .cancelled:
                if case .complete = rhs {
                    return true
                }
                return false
            case .failed(_):
                if case .failed = rhs {
                    return true
                }
                return false
            }
        }

        case waiting
        case active(Progress)
        case complete(FileDetails)
        case cancelled
        case failed(Error)
    }

    var isCancelled: Bool {
        return cancellationToken.isCancelled
    }

    let id = UUID()
    let cancellationToken = CancellationToken()
    let item: FileReference

    var status: Status

    var isActive: Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        switch status {
        case .waiting, .active:
            return true
        case .complete, .cancelled, .failed:
            return false
        }
    }

    init(item: FileReference, status: Status = .waiting) {
        self.item = item
        self.status = status
    }

    func setStatus(_ status: Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }

    func cancel() {
        cancellationToken.cancel()
    }

    func checkCancellation() throws {
        return try cancellationToken.checkCancellation()
    }

    /**
     * Convenience. Performs the work on the current queue catching any exceptions, updates the transfer accordingly,
     * and re-throws the error.
     */
    func withThrowing(_ perform: (Progress) throws -> FileDetails) throws {
        do {
            let progress = Progress()
            setStatus(.active(progress))
            let result = try perform(progress)
            setStatus(.complete(result))
        } catch {
            setStatus(.failed(error))
            throw error
        }
    }

}
