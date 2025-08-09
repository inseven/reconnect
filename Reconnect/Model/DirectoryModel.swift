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
class DirectoryModel {

    var navigationTitle: String? {
        return name(for: path)
    }

    let applicationModel: ApplicationModel
    let transfersModel: TransfersModel

    var files: [FileServer.DirectoryEntry] = []

    var fileSelection = Set<FileServer.DirectoryEntry.ID>()

    nonisolated let driveInfo: FileServer.DriveInfo
    nonisolated let path: String
    
    var lastError: Error? = nil

    @ObservationIgnored
    private let navigationHistory: NavigationHistory

    init(applicationModel: ApplicationModel,
         transfersModel: TransfersModel,
         navigationHistory: NavigationHistory,
         driveInfo: FileServer.DriveInfo,
         path: String) {
        self.applicationModel = applicationModel
        self.transfersModel = transfersModel
        self.navigationHistory = navigationHistory
        self.driveInfo = driveInfo
        self.path = path
    }

    func start() async {
        update()
    }

    // TODO: I think this is for the history and should probably live in that?
    // TODO: Push tuples onto the navigation history with a label as well?
    func name(for path: String) -> String? {
        if path.isRoot {
            return driveInfo.displayName
        }
        return path.lastWindowsPathComponent
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
        navigationHistory.navigate(.directory(driveInfo, path))
    }

    private func update() {
        self.files = []
        self.run { [path] in
            let files = try self.applicationModel.fileServer.dirSync(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            DispatchQueue.main.sync {
                self.files = files
                self.fileSelection = self.fileSelection.intersection(files.map({ $0.id }))
            }
        }
    }

    func delete(_ selection: Set<FileServer.DirectoryEntry.ID>) {
        run {
            for path in selection {
                if path.isWindowsDirectory {
                    try self.applicationModel.fileServer.rmdir(path: path)
                } else {
                    try self.applicationModel.fileServer.remove(path: path)
                }
                DispatchQueue.main.sync {
                    self.files.removeAll { $0.path == path }
                    self.fileSelection.remove(path)
                }
            }
        }
    }

    func rename(file: FileServer.DirectoryEntry, to newName: String) {
        run {
            let newPath = file.path
                .deletingLastWindowsPathComponent
                .appendingWindowsPathComponent(newName, isDirectory: file.isDirectory)
            do {
                try self.applicationModel.fileServer.rename(from: file.path, to: newPath)
            } catch {
                self.refresh()
                throw error
            }
            DispatchQueue.main.sync {
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
                let urls = try await withThrowingTaskGroup(of: URL.self) { [transfersModel] group in
                    for file in files {
                        group.addTask {
                            return try await transfersModel.download(from: file,
                                                                     to: destinationURL,
                                                                     process: convertFiles ? FileConverter.convertFiles : FileConverter.identity)
                        }
                    }
                    var results: [URL] = []
                    for try await url in group {
                        results.append(url)
                    }
                    return results
                }
                completion(.success(urls))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func upload(url: URL) {
        TransfersWindow.reveal()
        Task {
            try? await self.transfersModel.upload(from: url, to: path + url.lastPathComponent)
            self.refresh()
        }
    }

}

extension DirectoryModel: FileManageable {

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

    var canOpenSelection: Bool {
        guard
            fileSelection.count == 1,
            let file = fileSelection.first
        else {
            return false
        }
        return file.isWindowsDirectory
    }

    var canCreateNewFolder: Bool {
        return driveInfo.isWriteable
    }

    func createNewFolder() {
        run { [path] in

            // Get the names of the files and folders in the current path.
            let names = try self.applicationModel.fileServer
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
            try self.applicationModel.fileServer.mkdir(path: folderPath)
            let files = try self.applicationModel.fileServer.dirSync(path: path)
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

    var canDelete: Bool {
        return driveInfo.isWriteable && !fileSelection.isEmpty
    }

    func delete() {
        delete(fileSelection)
    }

    var canDownload: Bool {
        return !fileSelection.isEmpty
    }

    func download() {
        download(to: applicationModel.downloadsURL,
                 convertFiles: applicationModel.convertFiles,
                 completion: { _ in })
    }

}

extension DirectoryModel: ParentNavigable {

    var canNavigateToParent: Bool {
        return !path.isRoot
    }

    func navigateToParent() {
        navigate(to: path.deletingLastWindowsPathComponent)
    }

}

extension DirectoryModel: Refreshable {

    var canRefresh: Bool {
        // TODO: Gate on whether we're refreshing already.
        return true
    }

    func refresh() {
        update()
    }

}
