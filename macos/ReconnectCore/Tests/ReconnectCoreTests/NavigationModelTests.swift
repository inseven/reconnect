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
@testable import ReconnectCore

enum Pages {
    case a
    case b
    case c
}

@MainActor
final class NavigationModelTests: XCTestCase {

    func test() async {
        let navigationModel = NavigationModel(element: Pages.a)
        XCTAssertEqual(navigationModel.current, .a)
        XCTAssertFalse(navigationModel.canGoBack())
        XCTAssertFalse(navigationModel.canGoForward())

        navigationModel.navigate(to: .b)
        XCTAssertEqual(navigationModel.current, .b)
        XCTAssertTrue(navigationModel.canGoBack())
        XCTAssertFalse(navigationModel.canGoForward())

        navigationModel.navigate(to: .c)
        XCTAssertEqual(navigationModel.current, .c)
        XCTAssertTrue(navigationModel.canGoBack())
        XCTAssertFalse(navigationModel.canGoForward())

        navigationModel.back()
        XCTAssertEqual(navigationModel.current, .b)
        XCTAssertTrue(navigationModel.canGoBack())
        XCTAssertTrue(navigationModel.canGoForward())

        navigationModel.back()
        XCTAssertEqual(navigationModel.current, .a)
        XCTAssertFalse(navigationModel.canGoBack())
        XCTAssertTrue(navigationModel.canGoForward())

        navigationModel.forward()
        XCTAssertEqual(navigationModel.current, .b)
        XCTAssertTrue(navigationModel.canGoBack())
        XCTAssertTrue(navigationModel.canGoForward())

        navigationModel.forward()
        XCTAssertEqual(navigationModel.current, .c)
        XCTAssertTrue(navigationModel.canGoBack())
        XCTAssertFalse(navigationModel.canGoForward())

        navigationModel.navigate(to: navigationModel.previousItems[0])
        XCTAssertEqual(navigationModel.current, .b)
        XCTAssertTrue(navigationModel.canGoBack())
        XCTAssertTrue(navigationModel.canGoForward())
    }

}
