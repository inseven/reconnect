// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2025 Jason Morley
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

import XCTest
@testable import Reconnect

final class NavigationStackTests: XCTestCase {

    func test() {
        var stack = NavigationStack()
        XCTAssertNil(stack.path)
        XCTAssertFalse(stack.canGoBack())
        XCTAssertFalse(stack.canGoForward())

        stack.navigate("C:\\")
        XCTAssertEqual(stack.path, "C:\\")
        XCTAssertFalse(stack.canGoBack())
        XCTAssertFalse(stack.canGoForward())

        stack.navigate("C:\\Screenshots\\")
        XCTAssertEqual(stack.path, "C:\\Screenshots\\")
        XCTAssertTrue(stack.canGoBack())
        XCTAssertFalse(stack.canGoForward())

        stack.back()
        XCTAssertEqual(stack.path, "C:\\")
        XCTAssertFalse(stack.canGoBack())
        XCTAssertTrue(stack.canGoForward())

        stack.forward()
        XCTAssertEqual(stack.path, "C:\\Screenshots\\")
        XCTAssertTrue(stack.canGoBack())
        XCTAssertFalse(stack.canGoForward())

        stack.back()
        XCTAssertEqual(stack.path, "C:\\")
        XCTAssertFalse(stack.canGoBack())
        XCTAssertTrue(stack.canGoForward())

        stack.navigate("C:\\Documents\\")
        XCTAssertEqual(stack.path, "C:\\Documents\\")
        XCTAssertTrue(stack.canGoBack())
        XCTAssertFalse(stack.canGoForward())
    }

}
