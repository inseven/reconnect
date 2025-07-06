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

import SwiftUI
import UniformTypeIdentifiers

import Algorithms
import OpoLua

import ReconnectCore

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

    var nextItems: [NavigationHistory.Item] {
        return navigationHistory.nextItems
    }

    var path: String? {
        return navigationHistory.path
    }

    var previousItems: [NavigationHistory.Item] {
        return navigationHistory.previousItems.reversed()
    }

    let fileServer = FileServer()

    let applicationModel: ApplicationModel
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

    private var navigationHistory = NavigationHistory()

    init(applicationModel: ApplicationModel, transfersModel: TransfersModel) {
        self.applicationModel = applicationModel
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

    private func run(task: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try task()
            } catch {
                DispatchQueue.main.sync {
                    self.lastError = error
                }
            }
        }
    }

    func navigate(to path: String) {
        navigationHistory.navigate(path)
        update()
    }

    func navigate(to item: NavigationHistory.Item) {
        navigationHistory.navigate(item)
        update()
    }

    func refresh() {
        update()
    }

    private func update() {
        guard let path = navigationHistory.path else {
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

    var canGoBack: Bool {
        return navigationHistory.canGoBack()
    }

    var canGoForward: Bool {
        return navigationHistory.canGoForward()
    }

    var canOpenEnclosingFolder: Bool {
        guard let path else {
            return false
        }
        return !path.isRoot
    }

    var canOpenSelection: Bool {
        guard
            fileSelection.count == 1,
            let file = fileSelection.first
        else {
            return false
        }
        return file.isWindowsDirectory
    }

    func back() {
        navigationHistory.back()
        update()
    }

    func forward() {
        navigationHistory.forward()
        update()
    }

    func openEnclosingFolder() {
        guard let path else {
            return
        }
        self.navigate(to: path.deletingLastWindowsPathComponent)
    }

    func openSelection() {
        guard
            fileSelection.count == 1,
            let file = fileSelection.first,
            file.isWindowsDirectory
        else {
            return
        }
        navigate(to: file)
    }

    func newFolder() {
        run {
            guard let path = self.path else {
                throw ReconnectError.invalidFilePath
            }

            // Get the names of the files and folders in the current path.
            let names = try self.fileServer
                .dirSync(path: path)
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
            try self.fileServer.mkdir(path: folderPath)
            let files = try self.fileServer.dirSync(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            // Update the model state.
            DispatchQueue.main.sync {
                self.files = files
            }

            // Select the folder.
            // There's something curious going on in SwiftUI here that means the selection doesn't get updated unless
            // we perform it after (I presume) the tree has been evaluated with the new file list.
            DispatchQueue.main.sync {
                self.fileSelection = Set([folderPath + "\\"])
            }
        }
    }

    func delete(_ selection: Set<FileServer.DirectoryEntry.ID>? = nil) {
        dispatchPrecondition(condition: .onQueue(.main))
        let selection = selection ?? fileSelection
        run {
            for path in selection {
                if path.isWindowsDirectory {
                    try self.fileServer.rmdir(path: path)
                } else {
                    try self.fileServer.remove(path: path)
                }
                DispatchQueue.main.sync {
                    self.files.removeAll { $0.path == path }
                    self.fileSelection.remove(path)
                }
            }
        }
    }

    func rename(file: FileServer.DirectoryEntry, to newName: String) {
        runAsync {
            let newPath = file.path
                .deletingLastWindowsPathComponent
                .appendingWindowsPathComponent(newName, isDirectory: file.isDirectory)
            do {
                try await self.fileServer.rename(from: file.path, to: newPath)
            } catch {
                self.refresh()
                throw error
            }
            await MainActor.run {
                var newFile = file
                newFile.path = newPath
                newFile.name = newName
                var updatedFiles = self.files
                updatedFiles.removeAll { $0.path == file.path }
                let index = updatedFiles.partitioningIndex {
                    return newFile.name.localizedStandardCompare($0.name) == .orderedAscending
                }
                updatedFiles.insert(newFile, at: index)
                self.files = updatedFiles
                if self.fileSelection.contains(file.id) {
                    self.fileSelection = self.fileSelection
                        .subtracting([file.id])
                        .union([newFile.id])
                }
            }
        }
    }

    // Download a set of files from the Psion to the destination directory URL.
    func download(_ selection: Set<FileServer.DirectoryEntry.ID>? = nil,
                  to: URL?,
                  convertFiles: Bool,
                  completion: @escaping (Result<Array<URL>, Error>) -> Void) {

        dispatchPrecondition(condition: .onQueue(.main))
        let destinationURL = to ?? applicationModel.downloadsURL
        precondition(destinationURL.hasDirectoryPath)
        let selection = selection ?? fileSelection
        let files = files.filter { selection.contains($0.id) }

        TransfersWindow.reveal()

        Task {
            do {
                var results: [URL] = []
                for file in files {
                    let url = try await transfersModel.download(from: file,
                                                                to: destinationURL,
                                                                convertFiles: convertFiles)
                    results.append(url)
                }
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func upload(url: URL) {
        TransfersWindow.reveal()
        runAsync {
            guard let path = self.path else {
                throw ReconnectError.invalidFilePath
            }
            try? await self.transfersModel.upload(from: url, to: path + url.lastPathComponent)
            self.refresh()
        }
    }

}
