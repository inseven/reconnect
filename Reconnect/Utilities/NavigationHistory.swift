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

@MainActor @Observable
class NavigationHistory {

    struct Item: Identifiable, Equatable {
        let id = UUID()
        let section: BrowserSection
    }

    var currentItem: Item? {
        guard let index else {
            return nil
        }
        return items[index]
    }

    var previousItems: [Item] {
        guard let index else {
            return []
        }
        return Array(items[0..<index]).reversed()
    }

    var nextItems: [Item] {
        guard let index else {
            return []
        }
        return Array(items[index+1..<items.count])
    }

    private var items: [Item] = []
    private var index: Int? = nil

    var generation = UUID()

    init(section: BrowserSection) {
        index = 0
        self.items = [Item(section: section)]
    }

    func back() {
        guard let index else {
            return
        }
        self.index = index - 1
        self.generation = UUID()
    }

    func forward() {
        assert(canGoForward())
        guard let index else {
            return
        }
        self.index = index + 1
        self.generation = UUID()
    }

    func canGoBack() -> Bool {
        guard let index else {
            return false
        }
        return index > 0
    }

    func canGoForward() -> Bool {
        guard let index else {
            return false
        }
        return index < items.count - 1
    }

    func navigate(to section: BrowserSection) {
        guard let index else {
            assert(items.count == 0)
            index = 0
            self.items = [Item(section: section)]
            return
        }
        assert(index < items.count)


        // Ignore requests to navigate to the current item.
        guard currentItem?.section != section else {
            return
        }

        // Push the item, truncting the list of items if we're already in the middle of the history.
        self.items = items[0...index] + [Item(section: section)]
        self.index = index + 1
        self.generation = UUID()
    }

    func navigate(_ item: Item) {
        guard let index = items.firstIndex(where: { $0 == item }) else {
            return
        }
        self.index = index
        self.generation = UUID()
    }

}
