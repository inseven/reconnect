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

import SwiftUI
import UniformTypeIdentifiers

import Algorithms
import OpoLuaCore

import ReconnectCore

@MainActor @Observable
class DirectoryModel {

    var navigationTitle: String? {
        return name(for: path)
    }

    @ObservationIgnored
    let applicationModel: ApplicationModel

    @ObservationIgnored
    private let navigationModel: NavigationModel<BrowserSection>

    @ObservationIgnored
    private let deviceModel: DeviceModel

    var isLoading: Bool = true
    var files: [FileServer.DirectoryEntry] = []
    var fileSelection = Set<FileServer.DirectoryEntry.ID>()

    nonisolated let driveInfo: FileServer.DriveInfo
    nonisolated let path: String
    
    var lastError: Error? = nil

    init(applicationModel: ApplicationModel,
         navigationModel: NavigationModel<BrowserSection>,
         deviceModel: DeviceModel,
         driveInfo: FileServer.DriveInfo,
         path: String) {
        self.applicationModel = applicationModel
        self.navigationModel = navigationModel
        self.deviceModel = deviceModel
        self.driveInfo = driveInfo
        self.path = path
    }

    func start() async {
        update()
    }

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
                    self.isLoading = false
                }
            }
        }
    }

    func navigate(to path: String) {
        navigationModel.navigate(to: .directory(deviceModel.id, driveInfo, path))
    }

    private func update() {
        self.isLoading = true
        self.files = []
        self.run { [path, deviceModel] in
            let files = try deviceModel.fileServer.dir(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            DispatchQueue.main.sync {
                self.files = files
                self.fileSelection = self.fileSelection.intersection(files.map({ $0.id }))
                self.isLoading = false
            }
        }
    }

    func delete(_ selection: Set<FileServer.DirectoryEntry.ID>) {
        run { [deviceModel] in
            for path in selection {
                if path.isWindowsDirectory {
                    try deviceModel.fileServer.rmdir(path: path)
                } else {
                    try deviceModel.fileServer.remove(path: path)
                }
                DispatchQueue.main.sync {
                    self.files.removeAll { $0.path == path }
                    self.fileSelection.remove(path)
                }
            }
        }
    }

    func rename(file: FileServer.DirectoryEntry, to newName: String) {
        run { [deviceModel] in
            let newPath = file.path
                .deletingLastWindowsPathComponent
                .appendingWindowsPathComponent(newName, isDirectory: file.isDirectory)
            do {
                try deviceModel.fileServer.rename(from: file.path, to: newPath)
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

    /**
     * Download a set of files from the Psion to the destination directory URL.
     *
     * If the source directory entry ids are omitted, this acts on the current selection.
     */
    func download(_ sourceDirectoryEntryIds: Set<FileServer.DirectoryEntry.ID>? = nil,
                  destinationDirectoryURL: URL?,
                  context: FileTransferContext) {

        dispatchPrecondition(condition: .onQueue(.main))
        let destinationDirectoryURL = destinationDirectoryURL ?? applicationModel.downloadsURL
        precondition(destinationDirectoryURL.hasDirectoryPath)
        let sourceDirectoryEntryIds = sourceDirectoryEntryIds ?? fileSelection
        let files = files.filter { sourceDirectoryEntryIds.contains($0.id) }

        for file in files {
            deviceModel.download(sourceDirectoryEntry: file,
                                 destinationURL: destinationDirectoryURL.appendingPathComponent(file.name),
                                 context: context)
        }
    }

    /**
     * Download a single file, represented by a directory entry id, from the Psion to the destination directory URL.
     */
    func download(sourceDirectoryEntryId: FileServer.DirectoryEntry.ID,
                  destinationDirectoryURL: URL,
                  context: FileTransferContext,
                  completion: @escaping (Result<URL, Error>) -> Void) {
        precondition(destinationDirectoryURL.hasDirectoryPath)
        guard let sourceDirectoryEntry = files.first(where: { $0.id == sourceDirectoryEntryId }) else {
            completion(.failure(PLPToolsError.noSuchFile))
            return
        }
        deviceModel.download(sourceDirectoryEntry: sourceDirectoryEntry,
                             destinationURL: destinationDirectoryURL.appendingPathComponent(sourceDirectoryEntry.name),
                             context: context,
                             completion: completion)
    }

    func upload(url: URL, context: FileTransferContext) {
        deviceModel.upload(sourceURL: url,
                           destinationPath: path + url.lastPathComponent,
                           context: context) { result in
            DispatchQueue.main.async {
                self.refresh()
            }
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
        run { [path, deviceModel] in

            // Get the names of the files and folders in the current path to allow us to check against existing names.
            // Since Psion file systems are case insensitive, we lowercase all entries for consistency.
            let names = try deviceModel.fileServer
                .dir(path: path)
                .map { $0.name.lowercased() }
                .reduce(into: Set()) { $0.insert($1) }

            // Select the first name (up to 99) that doesn't conflict.
            var folderName: String?
            for i: UInt8 in 0..<100 {
                let name = deviceModel.synthesizeNewFolderName(index: i)
                guard !names.contains(name.lowercased()) else {
                    continue
                }
                folderName = name
                break
            }

            guard let folderName else {
                throw PLPToolsError.invalidFileName
            }

            // Create the folder.
            let folderPath = path + folderName
            try deviceModel.fileServer.mkdir(path: folderPath)
            let files = try deviceModel.fileServer.dir(path: path)
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
        download(destinationDirectoryURL: applicationModel.downloadsURL, context: .interactive)
    }

}

extension DirectoryModel: ParentNavigable {

    var canNavigateToParent: Bool {
        return !path.isRoot
    }

    func navigateToParent() {
        navigate(to: path
            .deletingLastWindowsPathComponent
            .ensuringTrailingWindowsPathSeparator())
    }

}

extension DirectoryModel: Refreshable {

    var canRefresh: Bool {
        return !isLoading
    }

    var isRefreshing: Bool {
        return isLoading
    }

    func refresh() {
        update()
    }

}
