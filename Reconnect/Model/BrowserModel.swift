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

    var navigationTitle: String? {
        guard let path else {
            return nil
        }
        return name(for: path)
    }

    let fileServer = FileServer(host: "127.0.0.1", port: 7501)

    var drives: [FileServer.DriveInfo] = []
    var files: [FileServer.DirectoryEntry] = []

    var driveSelection: String? = nil {
        didSet {
            guard let driveSelection else {
                return
            }
            navigate(to: driveSelection + ":\\")
        }
    }

    var fileSelection = Set<FileServer.DirectoryEntry.ID>()

    var lastError: Error? = nil

    private var navigationStack = NavigationStack()

    init() {
        guard fileServer.connect() else {
            lastError = ReconnectError.unknown
            return
        }
    }

    func start() async {
        do {
            drives = try await fileServer.drives()
        } catch {
            lastError = error
        }
    }

    func name(for path: String) -> String? {
        if path.isRoot, let drive = drives.first(where: { path.hasPrefix($0.drive) }) {
            return drive.displayName
        }
        return path.windowsLastPathComponent
    }

    func image(for path: String) -> String {
        if path.isRoot, let drive = drives.first(where: { path.hasPrefix($0.drive) }) {
            return drive.image
        }
        return "Folder16"
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
        return navigationStack.previousItems.reversed()
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
                fileSelection = Set([folderPath + "\\"])
            } catch {
                print("Failed to create new folder with error \(error).")
                lastError = error
            }
        }
    }

    func delete(path: String) {
        Task {
            do {
                if path.isDirectory {
                    try await fileServer.rmdir(path: path)
                } else {
                    try await fileServer.remove(path: path)
                }
                update()
            } catch {
                print("Failed to delete item at path '\(path)' with error \(error).")
                lastError = error
            }
        }
    }

    func download(path: String) {
        Task {
            let fileManager = FileManager.default
            let downloadsUrl = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

            let filename = path.windowsLastPathComponent
            let destinationURL = downloadsUrl.appendingPathComponent(filename)

            do {
                try await fileServer.copyFile(fromRemotePath: path, toLocalPath: destinationURL.path)
            } catch {
                print("Failed to download file at path '\(path)' to destination path '\(destinationURL.path)' with error \(error).")
                lastError = error
            }

            do {
                if let directoryUrls = try? FileManager.default.contentsOfDirectory(at: downloadsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants) {
                    print(directoryUrls)
                }
            }
        }
    }

}
