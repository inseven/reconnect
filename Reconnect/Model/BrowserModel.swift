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
class BrowserModel {

    // TODO: Surface errors here.

    let fileServer = FileServer(host: "127.0.0.1", port: 7501)

    var files: [FileServer.DirectoryEntry] = []
    var selection = Set<FileServer.DirectoryEntry.ID>()
    var lastError: Error? = nil

    private var navigationStack = NavigationStack()

    init() {
        guard fileServer.connect() else {
            lastError = ReconnectError.general
            return
        }
        _ = fileServer.devlist()
    }

    func navigate(to path: String) {
        navigationStack.navigate(path)
        update()
    }

    func navigate(to item: NavigationStack.Item) {
        navigationStack.navigate(item)
        update()
    }

    func refresh() {
        update()
    }

    private func update() {
        guard let path = navigationStack.path else {
            return
        }
        self.files = []
        Task {
            do {
                let files = try await fileServer.dir(path: path)
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                self.files = files
            } catch {
                lastError = error
            }
        }
    }

    var path: String? {
        return navigationStack.path
    }

    var previousItems: [NavigationStack.Item] {
        return navigationStack.previousItems
    }

    var nextItems: [NavigationStack.Item] {
        return navigationStack.nextItems
    }

    func canGoBack() -> Bool {
        return navigationStack.canGoBack()
    }

    func back() {
        navigationStack.back()
        update()
    }

    func canGoForward() -> Bool {
        return navigationStack.canGoForward()
    }

    func forward() {
        navigationStack.forward()
        update()
    }

    func newFolder() {
        guard let path = navigationStack.path else {
            return
        }
        Task {
            do {
                let folderPath = path + "untitled folder"
                try await fileServer.mkdir(path: folderPath)
                let files = try await fileServer.dir(path: path)
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                self.files = files
                selection = Set([folderPath + "\\"])
            } catch {
                print("Failed to create new folder with error \(error).")
                lastError = error
            }
        }
    }

}
