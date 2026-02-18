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

import OpoLuaCore

import ReconnectCore

// Called on main.
protocol DeviceModelDelegate: AnyObject {

    func deviceModel(deviceModel: DeviceModel, didUpdateName name: String)
    func deviceModel(deviceModel: DeviceModel, willStartBackupWithIdentifier identifier: UUID)
    func deviceModel(deviceModel: DeviceModel, didFinishBackupWithIdentifier identifier: UUID, backup: Backup)
    func deviceModel(deviceModel: DeviceModel, didFailBackupWithIdentifier identifier: UUID, error: Error)

}

@Observable
class DeviceModel: Identifiable, Equatable, @unchecked Sendable {

    /**
     * Perform initial device configuration on connection and return a fully-configured device model.
     *
     * This is performed as a separate, asynchronous step to ensure that properties of the device model are available
     * syncrhonously by the time we have a full device model.
     *
     * Initialization can be cancelled at ay point in time by calling cancel.
     *
     * The completion block is called on a background queue.
     */
    static func initialize(applicationModel: ApplicationModel,
                           connectionDetails: DeviceConnectionDetails,
                           cancellationToken: CancellationToken = CancellationToken(),
                           completion: @escaping (Result<DeviceModel, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {

                // Bootstrap the connection to the Psion, inferring the type of the deivce we're connected to and its
                // limitations as we go. There are probably better appraoches to this, but this at least gets things
                // working, and we can revisit them in the future.

                // We check to see if we've been cancelled at each step of the initialization process to allow us to
                // exit early if the calling code has cancelled.

                // Create the servers for communicating with the Psion. These will be handed off, on success, to the
                // new device model.
                let fileServer = FileServer(port: connectionDetails.port)
                let remoteCommandServicesClient = RemoteCommandServicesClient(port: connectionDetails.port)

                // 1) Perform a drive listing. We know we can always safely do this.
                try cancellationToken.checkCancellation()
                let drives = try fileServer.drives()

                // 2) Get the internal drive.
                guard let internalDrive = drives.first(where: { $0.driveAttributes.contains(.internal) }) else {
                    throw PLPToolsError.E_PSI_FILE_NOTREADY
                }

                // 3) Infer that we're talking to an EPOC16 device by the presence of a RAM-drive labeled M.
                try cancellationToken.checkCancellation()
                let epoc16 = internalDrive.drive == "M"

                // 3) If we're EPOC16, we need to ensure the RPCS server is installed on the Psion, copying it if not.
                try cancellationToken.checkCancellation()
                if try (epoc16 && !fileServer.exists(path: "M:\\SYS$RPCS.IMG")) {
                    let rpcsServer = Bundle.main.url(forResource: "SYS$RPCS", withExtension: ".IMG")!
                    try fileServer.copyFile(fromLocalPath: rpcsServer.path, toRemotePath: "M:\\SYS$RPCS.IMG") { _, _ in return .continue }
                }

                // 4) Once we've made sure the RPCS server is present irrespective of the machine we're using, we can
                //    fetch the machine type.
                try cancellationToken.checkCancellation()
                let machineType = try remoteCommandServicesClient.getMachineType()

                // 5) We then use the machine type as a more fine-grained way to determine if it's safe to fetch the
                //    full machine info.
                try cancellationToken.checkCancellation()
                let machineInfo: RemoteCommandServicesClient.MachineInfo? = if machineType.isEpoc32 {
                    try remoteCommandServicesClient.getMachineInfo()
                } else {
                    nil
                }

                // 6) Check to see if the machine already has a Reconnect-managed unique identifier, creating one if
                //    necessary. We generate our own identifiers to work around EPOC16's lack of unique identifiers and
                //    give us a way to identify device sessions (between hard resets) instead of the device hardware
                //    itself.

                let configPath: String = epoc16 ? .epoc16ConfigPath : .epoc32ConfigPath

                // Ensure the config directory exists.
                let configDirectoryPath = configPath.deletingLastWindowsPathComponent
                if !(try fileServer.exists(path: configDirectoryPath)) {
                    try fileServer.mkdir(path: configDirectoryPath)
                }

                // Ccreate or read the device config.
                let deviceConfiguration: DeviceConfiguration
                if !(try fileServer.exists(path: configPath)) {
                    deviceConfiguration = DeviceConfiguration()
                    let data = try deviceConfiguration.data()
                    try fileServer.writeFile(path: configPath, data: data)
                } else {
                    let data = try fileServer.readFile(path: configPath)
                    let configuration = try DeviceConfiguration(data: data)
                    deviceConfiguration = configuration
                }

                // 7) And with all that done, it's safe to hand back to the UI with enough information to allow things
                //    to continue and conditionally display things correctly. 😬
                //
                //    Note that there's a tiny bit of magic in the constructor: we check to see if the device is EPOC16
                //    or EPOC32 and, conditionally create a section file server to use for file transfers on EPOC32;
                //    since EPOC16 only supports a single file server, we have to share it between tasks on these
                //    machines.
                let transfersFileServer = machineType.isEpoc32 ? FileServer(port: connectionDetails.port) : fileServer
                let deviceModel = DeviceModel(applicationModel: applicationModel,
                                              connectionDetails: connectionDetails,
                                              fileServer: fileServer,
                                              transfersFileServer: transfersFileServer,
                                              remoteCommandServicesClient: remoteCommandServicesClient,
                                              deviceConfiguration: deviceConfiguration,
                                              machineType: machineType,
                                              machineInfo: machineInfo,
                                              drives: drives,
                                              internalDrive: internalDrive)

                // Hand it back!
                completion(.success(deviceModel))

            } catch {
                completion(.failure(error))
            }

        }
    }

    static func == (lhs: DeviceModel, rhs: DeviceModel) -> Bool {
        return lhs.id != rhs.id
    }

    @MainActor
    var isCapturingScreenshot: Bool = false

    var id: UUID {
        return deviceConfiguration.id
    }
    
    var platform: Platform {
        return machineType.isEpoc32 ? .epoc32 : .epoc16
    }

    var installDirectory: String? {
        return machineType.isEpoc32 ? .epoc32InstallDirectory : .epoc16InstallDirectory
    }

    var screenshotPath: String {
        return machineType.isEpoc32 ? .epoc32ScreenshotPath : .epoc16ScreenshotPath
    }

    var screenshotToolPath: String {
        return machineType.isEpoc32 ? .epoc32ScreenshotToolPath : .epoc16ScreenshotToolPath
    }

    @ObservationIgnored
    private weak var applicationModel: ApplicationModel?

    @ObservationIgnored
    weak var delegate: DeviceModelDelegate?

    @MainActor
    var ownerInfo: String? = nil

    @MainActor
    var name: String

    let connectionDetails: DeviceConnectionDetails
    let fileServer: FileServer
    let transfersFileServer: FileServer
    let remoteCommandServicesClient: RemoteCommandServicesClient

    let machineType: RemoteCommandServicesClient.MachineType
    let machineInfo: RemoteCommandServicesClient.MachineInfo?
    let drives: [FileServer.DriveInfo]
    let internalDrive: FileServer.DriveInfo

    private let deviceConfiguration: DeviceConfiguration

    private let workQueue = DispatchQueue(label: "DeviceModel.workQueue")
    private let transfersQueue = DispatchQueue(label: "DeviceModel.transfersQueue")

    private init(applicationModel: ApplicationModel,
                 connectionDetails: DeviceConnectionDetails,
                 fileServer: FileServer,
                 transfersFileServer: FileServer,
                 remoteCommandServicesClient: RemoteCommandServicesClient,
                 deviceConfiguration: DeviceConfiguration,
                 machineType: RemoteCommandServicesClient.MachineType,
                 machineInfo: RemoteCommandServicesClient.MachineInfo?,
                 drives: [FileServer.DriveInfo],
                 internalDrive: FileServer.DriveInfo) {
        self.applicationModel = applicationModel
        self.connectionDetails = connectionDetails
        self.fileServer = fileServer
        self.transfersFileServer = transfersFileServer
        self.remoteCommandServicesClient = remoteCommandServicesClient
        self.deviceConfiguration = deviceConfiguration
        _name = deviceConfiguration.name
        self.machineType = machineType
        self.machineInfo = machineInfo
        self.drives = drives
        self.internalDrive = internalDrive
    }

    func start() {
        DispatchQueue.main.async { [self] in
            delegate?.deviceModel(deviceModel: self, didUpdateName: name)
        }
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            do {
                let ownerInfo = try remoteCommandServicesClient.getOwnerInfo()
                DispatchQueue.main.async {
                    self.ownerInfo = ownerInfo.joined(separator: "\n")
                }
            } catch {
                print("Failed to get owner info with error \(error).")
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    private func runInBackground(perform: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try perform()
            } catch {
                print("Failed to perform background operation with error \(error).")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Error"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    static let backupNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        dateFormatter.timeZone = .gmt
        return dateFormatter
    }()

    func setName(_ name: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            do {
                let configPath: String = platform == .epoc16 ? .epoc16ConfigPath : .epoc32ConfigPath
                let deviceConfiguration = DeviceConfiguration(id: id, name: name)
                let data = try deviceConfiguration.data()
                try fileServer.writeFile(path: configPath, data: data)
                DispatchQueue.main.async { [self] in
                    self.name = name
                    completion(nil)
                    delegate?.deviceModel(deviceModel: self, didUpdateName: name)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    @MainActor
    func backUp() {
        applicationModel?.showBackupWindow(deviceModel: self)
    }

    func backUp(drives: Set<FileServer.DriveInfo>,
                progress: Progress,
                cancellationToken: CancellationToken) throws -> Backup {
        dispatchPrecondition(condition: .notOnQueue(.main))

        let backupIdentifier = UUID()
        DispatchQueue.main.sync {
            self.delegate?.deviceModel(deviceModel: self, willStartBackupWithIdentifier: backupIdentifier)
        }

        do {

            let fileManager = FileManager.default

            // Determine the backup URL.
            // It might make sense to move this into a central backup manager in the future.
            let backupsURL = DispatchQueue.main.sync {
                return applicationModel?.backupsURL
            }
            guard let backupsURL else {
                throw ReconnectError.unknown
            }
            let backupSetURL = backupsURL.appendingPathComponent(id.uuidString, isDirectory: true)
            let destinationURL = backupSetURL
                .appendingPathComponent(Self.backupNameDateFormatter.string(from: Date()), isDirectory: true)

            // Ensure the backup set directory exists.
            if !fileManager.fileExists(at: backupSetURL) {
                try fileManager.createDirectory(at: backupSetURL, withIntermediateDirectories: true)
            }

            // Back up to a temporary directory to ensure partial backups don't pollute the backups directory.
            let backupURL = try fileManager.createTemporaryDirectory()
            defer {
                try? FileManager.default.removeItem(at: backupURL)
                // Check to see if we need to delete the temporary directory (in case of a failure).
                if fileManager.fileExists(at: backupURL) {
                    try? fileManager.removeItemLoggingErrors(at: backupURL)
                }
            }

            // TODO: Quit running apps.
            //       This needs some kind of mechanism to allow the user to force-close apps if necessary.

            // Recursively list all the files to be backed up, across all drives.
            // We do this all at once to allow us to report the progress more cleanly.
            progress.localizedDescription = "Listing files..."
            var files: [FileServer.DriveInfo: [FileServer.DirectoryEntry]] = [:]
            for drive in drives {
                files[drive] = try transfersFileServer.dir(path: drive.path,
                                                           recursive: true,
                                                           cancellationToken: cancellationToken)
                try cancellationToken.checkCancellation()
            }

            // Update the progress for the new file count.
            let fileCount = files.map { $1.count }.reduce(0, +)
            progress.totalUnitCount = Int64(fileCount)
            progress.localizedDescription = "Copying files..."

            // Iterate over the drives again, this time copying the files.
            for (drive, driveFiles) in files {

                // Create the target directory.
                let driveBackupURL = backupURL.appendingPathComponent(drive.drive, isDirectory: true)
                try fileManager.createDirectory(at: driveBackupURL, withIntermediateDirectories: true)

                // Copy the files.
                for file in driveFiles {

                    // Double-check that the file is contained by our (case-insensitive) directory.
                    guard file.path.lowercased().hasPrefix(drive.path.lowercased()) else {
                        throw PLPToolsError.E_PSI_FILE_NAME
                    }

                    // Determine the destination path.
                    let relativePath = String(file.path.dropFirst(drive.path.count))
                    let innerDestinationURL = driveBackupURL.appendingPathComponents(relativePath.windowsPathComponents)

                    // Create the destination directory, or copy the file.
                    progress.localizedAdditionalDescription = file.path
                    if file.path.isWindowsDirectory {
                        try fileManager.createDirectory(at: innerDestinationURL, withIntermediateDirectories: true)
                        progress.completedUnitCount += 1
                    } else {
                        let copyProgress = Progress()
                        progress.addChild(copyProgress, withPendingUnitCount: 1)
                        _ = try _downloadFile(sourceDirectoryEntry: file,
                                              destinationURL: innerDestinationURL,
                                              context: .backup,
                                              progress: copyProgress,
                                              cancellationToken: cancellationToken)
                    }

                    // Check to see if we've been cancelled.
                    try cancellationToken.checkCancellation()

                }
            }

            // Write the manifest.
            try cancellationToken.checkCancellation()
            let driveManifests = drives.map { drive in
                // TODO: We should consider including NCP_GET_UNIQUE_ID for incremental backups.
                return BackupManifest.Drive(drive: drive.drive,
                                            mediaType: drive.mediaType,
                                            driveAttributes: drive.driveAttributes,
                                            name: drive.name)
            }
            let manifest = BackupManifest(device: deviceConfiguration,
                                          platform: platform,
                                          date: .now,
                                          drives: driveManifests)
            try manifest.write(to: backupURL.appending(path: String.manifestFilename))

            // Move the backup to the final destination.
            try fileManager.moveItem(at: backupURL, to: destinationURL)
            let backup = Backup(manifest: manifest, url: destinationURL)

            // Notify our delegate.
            DispatchQueue.main.async {
                self.delegate?.deviceModel(deviceModel: self,
                                           didFinishBackupWithIdentifier: backupIdentifier,
                                           backup: backup)
            }

            return backup

        } catch {
            DispatchQueue.main.sync {
                self.delegate?.deviceModel(deviceModel: self,
                                           didFailBackupWithIdentifier: backupIdentifier,
                                           error: error)
            }
            throw error
        }
    }

    @MainActor
    func captureScreenshot() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let applicationModel else {
            return
        }

        let screenshotsURL = applicationModel.screenshotsURL
        let revealScreenshot = applicationModel.revealScreenshots
        isCapturingScreenshot = true

        let transfersModel = applicationModel.transfersModel

        runInBackground { [self, transfersModel] in

            defer {
                DispatchQueue.main.async {
                    self.isCapturingScreenshot = false
                }
            }

            // Check to see if the guest tools are installed.
            guard try fileServer.exists(path: screenshotToolPath) else {
                throw ReconnectError.missingTools
            }

            // Create a temporary directory.
            let fileManager = FileManager.default
            let temporaryDirectory = try fileManager.createTemporaryDirectory()
            defer {
                try? fileManager.removeItemLoggingErrors(at: temporaryDirectory)
            }

            // Take a screenshot.
            let timestamp = Date.now
            try remoteCommandServicesClient.execProgram(program: screenshotToolPath, args: "")
            sleep(5)

            // Perhaps the transfer model can use some paired down reference which includes the type?
            let screenshotDetails = try fileServer.getExtendedAttributes(path: screenshotPath)

            // Download and convert the screenshot.
            // This runs in the context of the transfers operation queue, but perhaps it would be cleaner to run this
            // work on our own device-specific executor, and just request a tracked operation that we bind to from the
            // transfers mdoel. Would keep it cleaner and avoid us serializing stuff with multiple devices connected.

            let temporaryFileURL = temporaryDirectory.appendingPathComponent(screenshotDetails.name)

            // Track the transfer using the transfers model.
            let transfer = transfersModel.newTransfer(fileReference: .remote(screenshotDetails))

            try transfer.withThrowing { progress in

                // Download the file.
                _ = try _downloadFile(sourceDirectoryEntry: screenshotDetails,
                                      destinationURL: temporaryFileURL,
                                      context: .copy,
                                      progress: progress,
                                      cancellationToken: transfer.cancellationToken)

                // Manually convert the file.
                let nameFormatter = DateFormatter()
                nameFormatter.dateFormat = "'Reconnect Screenshot' yyyy-MM-dd 'at' HH.mm.ss"
                let name = nameFormatter.string(from: timestamp)
                let outputURL = screenshotsURL.appendingPathComponent(name, conformingTo: .png)
                if machineType.isEpoc32 {
                    try PsiLuaEnv().convertMultiBitmap(sourceURL: temporaryFileURL, destinationURL: outputURL, type: .png)
                } else {
                    try PsiLuaEnv().convertPicToPNG(sourceURL: temporaryFileURL, destinationURL: outputURL)
                }

                // Cleanup.
                try fileServer.remove(path: screenshotPath)

                // Reveal the screenshot.
                if revealScreenshot {
                    DispatchQueue.main.async {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }

                return Transfer.FileDetails(localURL: outputURL)
            }

        }

    }

    @MainActor
    func installGuestTools() {
        let installerURL = if machineType.isEpoc32 {
            Bundle.main.url(forResource: "ReconnectTools.sis", withExtension: nil)!
        } else {
            Bundle.main.url(forResource: "RCONNECT.SIS", withExtension: nil)!
        }
        applicationModel?.showInstallerWindow(file: File(referencing: installerURL))
    }

    /**
     * Download a remote Psion file or directory, displaying progress in the transfers window.
     *
     * This is a high-level wrapper which is intended to be used directly by the UI and has some side effects not
     * present in the lower level internal functions. Specifically, upon completion, it will move the temporary files
     * to the first available free filename (computed by appending an index to the filename). This is intended to match
     * the download behavior in apps like Safari.
     *
     * This is a hard API to hold correctly because, as implemented, the calling code and the internal conversion have
     * to agree on the output name and extension. This is a side effect of how hard it is to hold Apple's drag-and-drop
     * `NSItemProvider` APIs to support on-demand user-interactive file conversion. Hopefully I can find a way to use
     * those APIs better that will make it easier to drop the `destinationURL` from this API.
     */
    @MainActor
    func download(sourceDirectoryEntry: FileServer.DirectoryEntry,
                  destinationURL: URL,
                  context: FileTransferContext,
                  completion: @escaping (Result<URL, Error>) -> Void = { _ in }) {
        guard let transfersModel = applicationModel?.transfersModel else {
            completion(.failure(ReconnectError.cancelled))
            return
        }
        let transfer = transfersModel.newTransfer(fileReference: .remote(sourceDirectoryEntry))
        transfersQueue.async { [self] in
            let progress = Progress()
            transfer.setStatus(.active(progress))
            do {
                let fileManager = FileManager.default
                let temporaryDirectoryURL = try fileManager.createTemporaryDirectory()
                defer {
                    try? fileManager.removeItem(at: temporaryDirectoryURL)
                }
                let temporaryURL = temporaryDirectoryURL.appendingPathComponent(sourceDirectoryEntry.name)
                let url = try _download(sourceDirectoryEntry: sourceDirectoryEntry,
                                        destinationURL: temporaryURL,
                                        context: context,
                                        progress: progress,
                                        cancellationToken: transfer.cancellationToken)

                let destinationFilename = destinationURL.lastPathComponent.replacingPathExtension(url.pathExtension)
                let finalURL = try fileManager.safelyMoveItem(at: url, toPreferredURL: destinationURL.deletingLastPathComponent().appendingPathComponent(destinationFilename))
                let result = Transfer.FileDetails(localURL: (finalURL))
                transfer.setStatus(.complete(result))
                completion(.success(finalURL))
            } catch {
                transfer.setStatus(.failed(error))
                completion(.failure(error))
            }
        }
    }

    @MainActor
    func upload(sourceURLs: [URL],
                destinationDirectoryPath: String,
                context: FileTransferContext,
                completion: @escaping ([Result<FileServer.DirectoryEntry, Error>]) -> Void = { _ in }) {
        guard let transfersModel = applicationModel?.transfersModel else {
            let errors = sourceURLs.map { _ -> Result<FileServer.DirectoryEntry, Error> in
                return .failure(PLPToolsError.E_PSI_FILE_CANCEL)
            }
            DispatchQueue.main.async {
                completion(errors)
            }
            return
        }

        // We use a dispatch group to coordinate results so we can report them in the same completion handler.
        let dispatchGroup = DispatchGroup()
        var results: [Result<FileServer.DirectoryEntry, Error>] = []

        for sourceURL in sourceURLs {
            dispatchGroup.enter()

            // Create and register the model that will represent the transfer in the UI.
            let transfer = transfersModel.newTransfer(fileReference: .local(sourceURL))

            // Dispatch the work to the transfers queue.
            transfersQueue.async { [self] in
                do {
                    try transfer.withThrowing { progress in
                        let progress = Progress()
                        transfer.setStatus(.active(progress))
                        let destinationPath = destinationDirectoryPath
                            .appendingWindowsPathComponent(sourceURL.lastPathComponent)
                        let directoryEntry = try _upload(sourceURL: sourceURL,
                                                         destinationPath: destinationPath,
                                                         context: context,
                                                         progress: progress,
                                                         cancellationToken: transfer.cancellationToken)
                        results.append(.success(directoryEntry))
                        return Transfer.FileDetails(remoteDirectoryEntry: directoryEntry,
                                                    size: UInt64(directoryEntry.size))
                    }
                    dispatchGroup.leave()
                } catch {
                    results.append(.failure(error))
                    dispatchGroup.leave()
                }
            }
        }

        // Once all the transfers our complete, our dispatch group will be notified.
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }

    public func runProgram(path: String) throws {
        let attributes = try fileServer.getExtendedAttributes(path: path)
        if attributes.uid1 == .dynamicLibraryUid {
            try remoteCommandServicesClient.execProgram(program: path)
        } else {
            try remoteCommandServicesClient.execProgram(program: "Z:\\System\\Apps\\OPL\\OPL.app", args: "A" + path)
        }
    }

    /**
     * Return a new folder name with a specific count.
     *
     * The expectation is that this will be called with increasing values of `index` (starting at 0), until a unique
     * name is found. It is implemented as a function (as opposed to simply returning a default new folder basename to
     * allow for per-platform customization around how the name changes with different values of index (e.g., EPOC16
     * does not permit spaces in files, while EPOC32 does).
     *
     * This maybe localized in the future.
     */
    func synthesizeNewFolderName(index: UInt8) -> String {
        if machineType.isEpoc32 {
            if index == 0 {
                return "untitled folder"
            } else {
                return "untitled folder \(index)"
            }
        } else {
            if index == 0 {
                return "FOLDER"
            } else {
                return "FOLDER\(index)"
            }
        }
    }

}

// File transfer conveniences.

extension DeviceModel {

    /**
     * Download any remote Psion file or directory.
     *
     * Internally this calls `downloadFile` or `downloadDirectory` (which in turn will call `downloadFile` for
     * individual file transfers).
     */
    fileprivate func _download(sourceDirectoryEntry: FileServer.DirectoryEntry,
                               destinationURL: URL,
                               context: FileTransferContext,
                               progress: Progress,
                               cancellationToken: CancellationToken) throws -> URL {
        dispatchPrecondition(condition: .notOnQueue(.main))
        if sourceDirectoryEntry.isDirectory {
            return try _downloadDirectory(sourcePath: sourceDirectoryEntry.path,
                                          destinationURL: destinationURL,
                                          context: context,
                                          progress: progress,
                                          cancellationToken: cancellationToken)
        } else {
            return try _downloadFile(sourceDirectoryEntry: sourceDirectoryEntry,
                                     destinationURL: destinationURL,
                                     context: context,
                                     progress: progress,
                                     cancellationToken: cancellationToken)
        }
    }

    /**
     * Download a remote Psion file.
     */
    fileprivate func _downloadFile(sourceDirectoryEntry: FileServer.DirectoryEntry,
                                   destinationURL: URL,
                                   context: FileTransferContext,
                                   progress: Progress,
                                   cancellationToken: CancellationToken) throws -> URL {
        dispatchPrecondition(condition: .notOnQueue(.main))
        assert(!sourceDirectoryEntry.isDirectory)

        let fileManager = FileManager.default

        // Set the progress.
        progress.totalUnitCount = Int64(sourceDirectoryEntry.size)

        // Create a temporary directory to download to.
        let temporaryDirectoryURL = try fileManager.createTemporaryDirectory()
        let temporaryURL = temporaryDirectoryURL.appendingPathComponent(sourceDirectoryEntry.name)
        defer {
            try? fileManager.removeItemLoggingErrors(at: temporaryDirectoryURL)
        }

        // Download the file.
        try transfersFileServer.copyFile(fromRemotePath: sourceDirectoryEntry.path,
                                         toLocalPath: temporaryURL.path) { current, total in
            progress.completedUnitCount = Int64(current)
            progress.totalUnitCount = Int64(total)
            return cancellationToken.isCancelled ? .cancel : .continue
        }
        progress.completedUnitCount = progress.totalUnitCount

        // Check to see if we've been cancelled.
        try cancellationToken.checkCancellation()

        // Move the file to the destination path.
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)

        // Check to see if the file needs transforming.
        let convertFiles = DispatchQueue.main.sync {
            guard let applicationModel else {
                return false
            }
            switch context {
            case .drag:
                return applicationModel.convertDraggedFiles
            case .interactive:
                return applicationModel.convertFiles
            case .backup, .copy:
                return false
            }
        }
        let conversion = convertFiles ? FileConverter.convertFiles : FileConverter.identity
        let convertedURL = try conversion(sourceDirectoryEntry, destinationURL)

        return convertedURL
    }

    /**
     * Download the contents of a remote Psion directory.
     *
     * Under the hood, this first performs an initial recurisve listing of the directory, downloads each file
     * sequentially to a temporary directory, and finally moves the temporary directory to the requested URL.
     */
    fileprivate func _downloadDirectory(sourcePath: String,
                                        destinationURL: URL,
                                        context: FileTransferContext,
                                        progress: Progress,
                                        cancellationToken: CancellationToken) throws -> URL {
        dispatchPrecondition(condition: .notOnQueue(.main))
        assert(sourcePath.isWindowsDirectory)

        let fileManager = FileManager.default

        // Create a temporary destination directory (we move this to the destination URL once the download is complete).
        let temporaryDirectoryURL = try fileManager.createTemporaryDirectory()
        defer {
            // Check to see if we need to delete the temporary directory (in case of a failure).
            if fileManager.fileExists(at: temporaryDirectoryURL) {
                try? fileManager.removeItemLoggingErrors(at: temporaryDirectoryURL)
            }
        }

        // Recursively list the files to work out what we need to download.
        progress.localizedDescription = "Listing files..."
        let files = try transfersFileServer.dir(path: sourcePath,
                                                recursive: true,
                                                cancellationToken: cancellationToken)

        // Update the progress accordingly.
        progress.totalUnitCount = Int64(files.count)
        progress.localizedDescription = "Copying files..."

        // Iterate over the files and copy each one in turn.
        try cancellationToken.checkCancellation()
        for file in files {

            // Double-check that the file is contained by our (case-insensitive) directory.
            guard file.path.lowercased().hasPrefix(sourcePath.lowercased()) else {
                throw PLPToolsError.E_PSI_FILE_NAME
            }

            // Determine the destination path.
            let relativePath = String(file.path.dropFirst(sourcePath.count))
            let innerDestinationURL = temporaryDirectoryURL.appendingPathComponents(relativePath.windowsPathComponents)

            // Create the destination directory, or copy the file.
            progress.localizedAdditionalDescription = file.path
            if file.path.isWindowsDirectory {
                try fileManager.createDirectory(at: innerDestinationURL, withIntermediateDirectories: true)
                progress.completedUnitCount += 1
            } else {
                let copyProgress = Progress()
                progress.addChild(copyProgress, withPendingUnitCount: 1)
                _ = try _downloadFile(sourceDirectoryEntry: file,
                                      destinationURL: innerDestinationURL,
                                      context: context,
                                      progress: copyProgress,
                                      cancellationToken: cancellationToken)
            }

            // Check to see if we've been cancelled.
            try cancellationToken.checkCancellation()
        }

        // Move to the requested destination.
        try fileManager.moveItem(at: temporaryDirectoryURL, to: destinationURL)

        return destinationURL
    }

    func _upload(sourceURL: URL,
                 destinationPath: String,
                 context: FileTransferContext,
                 progress: Progress,
                 cancellationToken: CancellationToken) throws -> FileServer.DirectoryEntry {
        dispatchPrecondition(condition: .notOnQueue(.main))
        if FileManager.default.directoryExists(at: sourceURL) {
            return try _uploadDirectory(sourceURL: sourceURL,
                                        destinationPath: destinationPath,
                                        context: context,
                                        progress: progress,
                                        cancellationToken: cancellationToken)
        } else {
            return try _uploadFile(sourceURL: sourceURL,
                                   destinationPath: destinationPath,
                                   context: context,
                                   progress: progress,
                                   cancellationToken: cancellationToken)
        }
    }

    func _uploadFile(sourceURL: URL,
                     destinationPath: String,
                     context: FileTransferContext,
                     progress: Progress,
                     cancellationToken: CancellationToken) throws -> FileServer.DirectoryEntry {
        dispatchPrecondition(condition: .notOnQueue(.main))
        assert(!sourceURL.hasDirectoryPath)

        let fileManager = FileManager.default

        // Read the local file size so we can set the progress total unit count.
        let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
        let size = attributes[.size] as! Int64
        progress.totalUnitCount = size

        // Upload the file.
        try transfersFileServer.copyFile(fromLocalPath: sourceURL.path,
                                         toRemotePath: destinationPath) { current, total in
            progress.completedUnitCount = Int64(current)
            progress.totalUnitCount = Int64(total)
            return cancellationToken.isCancelled ? .cancel : .continue
        }

        // Read the new file's metadata.
        let directoryEntry = try transfersFileServer.getExtendedAttributes(path: destinationPath)

        // Iterate over the files and copy each one in turn.
        try cancellationToken.checkCancellation()

        return directoryEntry
    }

    func _uploadDirectory(sourceURL: URL,
                          destinationPath: String,
                          context: FileTransferContext,
                          progress: Progress,
                          cancellationToken: CancellationToken) throws -> FileServer.DirectoryEntry {
        dispatchPrecondition(condition: .notOnQueue(.main))
        assert(sourceURL.hasDirectoryPath)

        let fileManager = FileManager.default

        // Recursively list the files to work out what we need to upload.
        let files = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { $0.lastPathComponent != ".DS_Store" }

        // Create the directory to upload to.
        try transfersFileServer.mkdir(path: destinationPath)

        // Iterate over the files and copy each one in turn.
        try cancellationToken.checkCancellation()
        for file in files {

            // Double-check that the file is contained by our directory.
            guard file.path.hasPrefix(sourceURL.path) else {
                throw PLPToolsError.E_PSI_FILE_NAME
            }

            // Determine the destination path.
            let relativePath = String(file.path.dropFirst(sourceURL.path().count))
            let innerDestinationPath = destinationPath.appendingWindowsPathComponent(relativePath)

            // Create the destination directory, or copy the file.
            progress.localizedAdditionalDescription = file.path
            if file.hasDirectoryPath {
                try transfersFileServer.mkdir(path: innerDestinationPath)
                progress.completedUnitCount += 1
            } else {
                let copyProgress = Progress()
                progress.addChild(copyProgress, withPendingUnitCount: 1)

                // Read the local file size so we can set the progress total unit count.
                let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
                let size = attributes[.size] as! Int64
                copyProgress.totalUnitCount = size

                // Upload the file.
                try transfersFileServer.copyFile(fromLocalPath: file.path,
                                                 toRemotePath: innerDestinationPath) { current, total in
                    copyProgress.completedUnitCount = Int64(current)
                    copyProgress.totalUnitCount = Int64(total)
                    return cancellationToken.isCancelled ? .cancel : .continue
                }
                copyProgress.completedUnitCount = copyProgress.totalUnitCount
            }

            // Check to see if we've been cancelled.
            try cancellationToken.checkCancellation()
        }

        // Read the new file's metadata.
        let directoryEntry = try transfersFileServer.getExtendedAttributes(path: destinationPath)

        // Iterate over the files and copy each one in turn.
        try cancellationToken.checkCancellation()

        return directoryEntry
    }

}
