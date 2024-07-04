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

// TODO: Main Actor?
@Observable
class Transfer: Identifiable {

    enum Status: Equatable {

        static func == (lhs: Transfer.Status, rhs: Transfer.Status) -> Bool {
            switch lhs {
            case .waiting:
                if case .waiting = rhs {
                    return true
                }
            case .active(let lhsProgress):
                if case let .active(rhsProgress) = rhs {
                    return lhsProgress == rhsProgress
                }
            case .complete:
                if case .complete = rhs {
                    return true
                }
            case .cancelled:
                if case .complete = rhs {
                    return true
                }
            case .failed(_):
                if case .failed = rhs {
                    return true
                }
            }
            return false
        }

        case waiting
        case active(Float)
        case complete
        case cancelled
        case failed(Error)
    }

    let id = UUID()

    var title: String
    var status: Status
    var task: Task<Void, Never>? = nil

    var isActive: Bool {
        switch status {
        case .waiting, .active:
            return true
        case .complete, .cancelled, .failed:
            return false
        }
    }

    init(title: String, action: @escaping (Transfer) async throws -> Void) {
        self.title = title
        self.status = .waiting
        let task = Task {
            do {
                try await action(self)
            } catch {
                print("Failed with error \(error).")
                self.setStatus(.failed(error))
            }
        }
        self.task = task
    }

    func setStatus(_ status: Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }

}
