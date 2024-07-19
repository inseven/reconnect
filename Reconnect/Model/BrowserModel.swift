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

import OpoLua

@MainActor @Observable
class BrowserModel {

    var isSelectionEmpty: Bool {
        return fileSelection.isEmpty
    }

    var navigationTitle: String? {
        guard let path else {
            return nil
        }
        return name(for: path)
    }

    var nextItems: [NavigationStack.Item] {
        return navigationStack.nextItems
    }

    var path: String? {
        return navigationStack.path
    }

    var previousItems: [NavigationStack.Item] {
        return navigationStack.previousItems.reversed()
    }

    let fileServer = FileServer()

    let transfersModel: TransfersModel

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

    init(transfersModel: TransfersModel) {
        self.transfersModel = transfersModel
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
        return path.lastWindowsPathComponent
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
        self.runAsync {
            let files = try await self.fileServer.dir(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            await MainActor.run {
                self.files = files
                self.fileSelection = self.fileSelection.intersection(files.map({ $0.id }))
            }
        }
    }

    private func runAsync(task: @escaping () async throws -> Void) {
        Task {
            do {
                try await task()
            } catch {
                await MainActor.run {
                    lastError = error
                }
            }
        }
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
        runAsync {
            guard let path = self.path else {
                throw ReconnectError.invalidFilePath
            }

            // Get the names of the files and folders in the current path.
            let names = try await self.fileServer
                .dir(path: path)
                .map { $0.name }
                .reduce(into: Set()) { $0.insert($1) }

            // Select the first name (up to 'untitled folder 99') that doesn't conflict.
            var name = "untitled folder"
            var folderNumber = 1
            while names.contains(name) {
                folderNumber += 1
                name = "untitled folder \(folderNumber)"
            }

            // Create the folder.
            let folderPath = path + name
            try await self.fileServer.mkdir(path: folderPath)
            let files = try await self.fileServer.dir(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            // Update the model state.
            await MainActor.run {
                self.files = files
            }

            // Select the folder.
            // There's something curious going on in SwiftUI here that means the selection doesn't get updated unless
            // we perform it after (I presume) the tree has been evaluated with the new file list.
            await MainActor.run {
                self.fileSelection = Set([folderPath + "\\"])
            }
        }
    }

    func delete(_ selection: Set<FileServer.DirectoryEntry.ID>? = nil) {
        let selection = selection ?? fileSelection
        runAsync {
            for path in selection {
                if path.isWindowsDirectory {
                    try await self.fileServer.rmdir(path: path)
                } else {
                    try await self.fileServer.remove(path: path)
                }
                await MainActor.run {
                    self.files.removeAll { $0.path == path }
                    self.fileSelection.remove(path)
                }
            }
        }
    }

    func download(_ selection: Set<FileServer.DirectoryEntry.ID>? = nil, convertFiles: Bool) {
        NSWorkspace.shared.open(.transfers)
        let selection = selection ?? fileSelection
        for path in selection {
            if path.isWindowsDirectory {
                downloadDirectory(path: path, convertFiles: convertFiles)
            } else {
                transfersModel.download(from: path, convertFiles: convertFiles)
            }
        }
    }

    private func downloadDirectory(path: String, convertFiles: Bool) {
        runAsync {
            let fileManager = FileManager.default
            let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let parentPath = path.deletingLastWindowsPathComponent.ensuringTrailingWindowsPathSeparator(isPresent: true)

            // Here we know we're downloading a directory, so we make sure the destination exists.
            try fileManager.createDirectory(at: downloadsURL.appendingPathComponent(path.lastWindowsPathComponent),
                                            withIntermediateDirectories: true)

            // Iterate over the recursive directory listing creating directories where necessary and downloading files.
            let files = try await self.fileServer.dir(path: path, recursive: true)
            for file in files {
                let relativePath = String(file.path.dropFirst(parentPath.count))
                let destinationURL = downloadsURL.appendingPathComponents(relativePath.windowsPathComponents)
                if file.isDirectory {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                } else {
                    self.transfersModel.download(from: file.path, to: destinationURL, convertFiles: convertFiles)
                }
            }
        }
    }

    func upload(url: URL) {
        NSWorkspace.shared.open(.transfers)
        runAsync {
            guard let path = self.path else {
                throw ReconnectError.invalidFilePath
            }
            self.transfersModel.upload(from: url, to: path + url.lastPathComponent)
        }
    }

}
