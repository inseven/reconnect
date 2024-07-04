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

            print("Downloading file at path '\(path)' to destination path '\(destinationURL.path)'...")
            transfersModel.add(filename) { transfer in
                try await self.fileServer.copyFile(fromRemotePath: path, toLocalPath: destinationURL.path) { progress, size in
                    transfer.setStatus(.active(Float(progress) / Float(size)))
                    return .continue
                }
                transfer.setStatus(.complete)
            }

            do {
                if let directoryUrls = try? FileManager.default.contentsOfDirectory(at: downloadsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants) {
                    print(directoryUrls)
                }
            }
        }
    }

    func upload(url: URL) {
        Task {
            do {
                guard let path else {
                    throw ReconnectError.invalidFilePath
                }
                let destinationPath = path + url.lastPathComponent
                print("Uploading file at path '\(url.path)' to destination path '\(destinationPath)'...")
                transfersModel.add(url.lastPathComponent) { transfer in
                    try await self.fileServer.copyFile(fromLocalPath: url.path, toRemotePath: destinationPath) { progress, size in
                        transfer.setStatus(.active(Float(progress) / Float(size)))
                        return .continue
                    }
                    transfer.setStatus(.complete)
                    self.update()
                }
            } catch {
                print("Failed to upload file with error \(error).")
                lastError = error
            }
        }
    }

}
