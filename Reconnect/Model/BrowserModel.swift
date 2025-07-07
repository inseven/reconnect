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
    var isCapturingScreenshot: Bool = false

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
        self.run {
            let files = try self.fileServer.dirSync(path: path)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            DispatchQueue.main.sync {
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
        run {
            let newPath = file.path
                .deletingLastWindowsPathComponent
                .appendingWindowsPathComponent(newName, isDirectory: file.isDirectory)
            do {
                try self.fileServer.rename(from: file.path, to: newPath)
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
            guard let path = self.path else {
                throw ReconnectError.invalidFilePath
            }
            try? await self.transfersModel.upload(from: url, to: path + url.lastPathComponent)
            self.refresh()
        }
    }

    func captureScreenshot() {
        dispatchPrecondition(condition: .onQueue(.main))

        let screenshotsURL = applicationModel.screenshotsURL
        let revealScreenshot = applicationModel.revealScreenshots
        isCapturingScreenshot = true

        run { [transfersModel] in

            defer {
                DispatchQueue.main.async {
                    self.isCapturingScreenshot = false
                }
            }

            let nameFormatter = DateFormatter()
            nameFormatter.dateFormat = "'Reconnect Screenshot' yyyy-MM-dd 'at' HH.mm.ss"

            let fileManager = FileManager.default
            let fileServer = FileServer()
            let client = RemoteCommandServicesClient()

            // Check to see if the guest tools are installed.
            guard try fileServer.exists(path: .reconnectToolsStubPath) else {
                throw ReconnectError.missingTools
            }

            // Create a temporary directory.
            let temporaryDirectory = try fileManager.createTemporaryDirectory()
            defer {
                try? fileManager.removeItemLoggingErrors(at: temporaryDirectory)
            }

            // Take a screenshot.
            print("Taking screenshot...")
            let timestamp = Date.now
            try client.execProgram(program: .screenshotToolPath, args: "")
            sleep(5)

            // Rename the screenshot before transferring it to allow us to defer renaming to the transfers model.
            let name = nameFormatter.string(from: timestamp)
            let screenshotPath = "C:\\\(name).mbm"
            try fileServer.rename(from: .screenshotPath, to: screenshotPath)  // TODO: Sync version of this?

            // TODO: This feels like overkill as a way to synthesize a directory entry.
            // Perhaps the transfer model can use some paired down reference which includes the type?
            let screenshotDetails = try fileServer.getExtendedAttributesSync(path: screenshotPath)

            TransfersWindow.reveal()

            Task {

                // Download and convert the screenshot.
                let outputURL = try await transfersModel.download(from: screenshotDetails,
                                                                  to: screenshotsURL) { entry, url in
                    let destinationURL = url.deletingLastPathComponent()
                    let outputURL = destinationURL.appendingPathComponent(url.lastPathComponent.deletingPathExtension,
                                                                          conformingTo: .png)
                    try PsiLuaEnv().convertMultiBitmap(at: url, to: outputURL, type: .png)
                    try FileManager.default.removeItem(at: url)
                    return outputURL
                }

                // Cleanup.
                try fileServer.remove(path: screenshotPath)

                // Reveal the screenshot.
                await MainActor.run {
                    if revealScreenshot {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }

            }

        }
    }

}
