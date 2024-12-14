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

@MainActor @Observable
class Transfer: Identifiable {

    struct FileDetails: Equatable {
        let url: URL
        let size: UInt64
    }

    enum Status: Equatable {

        static func == (lhs: Transfer.Status, rhs: Transfer.Status) -> Bool {
            switch lhs {
            case .waiting:
                if case .waiting = rhs {
                    return true
                }
                return false
            case .active(let lhsProgress, let lhsSize):
                if case let .active(rhsProgress, rhsSize) = rhs {
                    return lhsProgress == rhsProgress && lhsSize == rhsSize
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
        case active(UInt32, UInt32)
        case complete(FileDetails?)
        case cancelled
        case failed(Error)
    }

    var isCancelled: Bool {
        return lock.withLock {
            return _isCancelled
        }
    }

    let id = UUID()
    let item: FileReference
    let action: (Transfer) async throws -> Void

    var status: Status

    private var task: Task<Void, Never>? = nil
    private var lock = NSLock()
    private var _isCancelled: Bool = false

    var isActive: Bool {
        switch status {
        case .waiting, .active:
            return true
        case .complete, .cancelled, .failed:
            return false
        }
    }

    init(item: FileReference,
         status: Status = .waiting,
         action: @escaping ((Transfer) async throws -> Void) = { _ in }) {
        self.item = item
        self.status = status
        self.action = action
    }

    func run() async throws {
        self.task = Task {
            do {
                return try await action(self)
            } catch {
                print("Failed with error \(error).")
                self.setStatus(.failed(error))
            }
        }
        await task?.value
    }

    func setStatus(_ status: Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }

    func cancel() {
        task?.cancel()
        lock.withLock {
            _isCancelled = true
        }
    }

}
