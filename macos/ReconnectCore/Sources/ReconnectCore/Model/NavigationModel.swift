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

public protocol NavigationModelDelegate<Element>: AnyObject {

    associatedtype Element: Hashable

    func navigationModel(_ navigationModel: NavigationModel<Element>, canNavigateToItem item: Element) -> Bool

}

@MainActor @Observable
public class NavigationModel<Element: Hashable> {

    public struct Item: Identifiable, Equatable {
        public let id = UUID()
        public let element: Element
    }

    private var currentItem: Item {
        return items[index]
    }

    public var current: Element {
        return currentItem.element
    }

    public var previousItems: [Item] {
        return Array(items[0..<index]).reversed()
    }

    public var nextItems: [Item] {
        return Array(items[index+1..<items.count])
    }

    private var items: [Item] = []
    private var index: Int = 0

    public var generation = UUID()

    public weak var delegate: (any NavigationModelDelegate<Element>)? = nil

    public init(element: Element) {
        index = 0
        self.items = [Item(element: element)]
    }

    public func back() {
        guard let previousIndex = previousNavigableIndex() else {
            return
        }
        self.index = previousIndex
        self.generation = UUID()
    }

    public func forward() {
        guard let nextIndex = nextNavigableIndex() else {
            return
        }
        self.index = nextIndex
        self.generation = UUID()
    }

    public func canGoBack() -> Bool {
        return previousNavigableIndex() != nil
    }

    public func previousNavigableIndex() -> Int? {
        for i in (0..<index).reversed() {
            guard canNavigate(to: items[i]) else {
                continue
            }
            return i
        }
        return nil
    }

    public func canGoForward() -> Bool {
        return nextNavigableIndex() != nil
    }

    public func navigate(to element: Element) {
        // Ignore requests to navigate to the current item.
        guard currentItem.element != element else {
            return
        }
        // Push the item, truncting the list of items if we're already in the middle of the history.
        self.items = items[0...index] + [Item(element: element)]
        self.index = index + 1
        self.generation = UUID()
    }

    public func nextNavigableIndex() -> Int? {
        for i in index+1..<items.count {
            guard canNavigate(to: items[i]) else {
                continue
            }
            return i
        }
        return nil
    }

    public func canNavigate(to item: Item) -> Bool {
        return delegate?.navigationModel(self, canNavigateToItem: item.element) ?? true
    }

    public func navigate(to item: Item) {
        guard let index = items.firstIndex(where: { $0 == item }) else {
            return
        }
        self.index = index
        self.generation = UUID()
    }

}
