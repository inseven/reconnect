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

    var nextItems: [NavigationStack.Item] {
        return navigationStack.nextItems
    }

    var path: String? {
        return navigationStack.path
    }

    var previousItems: [NavigationStack.Item] {
        return navigationStack.previousItems.reversed()
    }

    var transfersModel = TransfersModel()

    let fileServer: FileServer

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

    init(fileServer: FileServer) {
        self.fileServer = fileServer
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
            let folderPath = path + "untitled folder"
            try await self.fileServer.mkdir(path: folderPath)
            let files = try await self.fileServer.dir(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            self.files = files
            self.fileSelection = Set([folderPath + "\\"])
        }
    }

    func delete(path: String) {
        runAsync {
            if path.isWindowsDirectory {
                try await self.fileServer.rmdir(path: path)
            } else {
                try await self.fileServer.remove(path: path)
            }
            self.files.removeAll { $0.path == path }
        }
    }

    func download(from path: String, to destinationURL: URL? = nil) {
        Task {
            let fileManager = FileManager.default
            let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let filename = path.lastWindowsPathComponent
            let downloadURL = destinationURL ?? downloadsURL.appendingPathComponent(filename)
            print("Downloading file at path '\(path)' to destination path '\(downloadURL.path)'...")
            transfersModel.add(filename) { transfer in
                try await self.fileServer.copyFile(fromRemotePath: path, toLocalPath: downloadURL.path) { progress, size in
                    transfer.setStatus(.active(Float(progress) / Float(size)))
                    return .continue
                }
                transfer.setStatus(.complete)
            }
        }
    }

    func downloadDirectory(path: String) {
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
                    self.download(from: file.path, to: destinationURL)
                }
            }
        }
    }

    func upload(url: URL) {
        runAsync {
            guard let path = self.path else {
                throw ReconnectError.invalidFilePath
            }
            let destinationPath = path + url.lastPathComponent
            print("Uploading file at path '\(url.path)' to destination path '\(destinationPath)'...")
            self.transfersModel.add(url.lastPathComponent) { transfer in
                try await self.fileServer.copyFile(fromLocalPath: url.path, toRemotePath: destinationPath) { progress, size in
                    transfer.setStatus(.active(Float(progress) / Float(size)))
                    return .continue
                }
                transfer.setStatus(.complete)
                self.update()
            }
        }
    }

}
