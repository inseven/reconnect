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

import Foundation

// Johannes would hate me for this as I believe misuse of it could lead to the indefinite blocking of a dispatch queue
// or thread.
public class UnsafeFuture<T, E: Error> {

    private var _result: Result<T, E>? = nil
    private let _sem = DispatchSemaphore(value: 0)

    public init() {
    }

    public func resolve(result: Result<T, E>) {
        guard _result == nil else {
            fatalError("Result is unexpectedly non-nil.")
        }
        _result = result
        _sem.signal()
    }

    public func success(_ value: T) {
        resolve(result: .success(value))
    }

    public func failure(_ error: E) {
        resolve(result: .failure(error))
    }

    public func get() throws -> T {
        return try result().get()
    }

    public func result() throws -> Result<T, E> {
        _sem.wait()
        guard let _result else {
            fatalError("Result is unexpectedly nil.")
        }
        return _result
    }

}
