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

import XCTest
@testable import Reconnect

// TODO: Re-enable these.
//final class NavigationHistoryTests: XCTestCase {
//
//    func test() {
//        var navigationHistory = NavigationHistory()
//        XCTAssertNil(navigationHistory.path)
//        XCTAssertFalse(navigationHistory.canGoBack())
//        XCTAssertFalse(navigationHistory.canGoForward())
//
//        navigationHistory.navigate("C:\\")
//        XCTAssertEqual(navigationHistory.path, "C:\\")
//        XCTAssertFalse(navigationHistory.canGoBack())
//        XCTAssertFalse(navigationHistory.canGoForward())
//
//        navigationHistory.navigate("C:\\Screenshots\\")
//        XCTAssertEqual(navigationHistory.path, "C:\\Screenshots\\")
//        XCTAssertTrue(navigationHistory.canGoBack())
//        XCTAssertFalse(navigationHistory.canGoForward())
//
//        navigationHistory.back()
//        XCTAssertEqual(navigationHistory.path, "C:\\")
//        XCTAssertFalse(navigationHistory.canGoBack())
//        XCTAssertTrue(navigationHistory.canGoForward())
//
//        navigationHistory.forward()
//        XCTAssertEqual(navigationHistory.path, "C:\\Screenshots\\")
//        XCTAssertTrue(navigationHistory.canGoBack())
//        XCTAssertFalse(navigationHistory.canGoForward())
//
//        navigationHistory.back()
//        XCTAssertEqual(navigationHistory.path, "C:\\")
//        XCTAssertFalse(navigationHistory.canGoBack())
//        XCTAssertTrue(navigationHistory.canGoForward())
//
//        navigationHistory.navigate("C:\\Documents\\")
//        XCTAssertEqual(navigationHistory.path, "C:\\Documents\\")
//        XCTAssertTrue(navigationHistory.canGoBack())
//        XCTAssertFalse(navigationHistory.canGoForward())
//    }
//
//}
