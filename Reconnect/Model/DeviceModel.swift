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

protocol DeviceModelDelegate: AnyObject {

    func deviceModel(deviceModel: DeviceModel, didFinishBackup backup: Backup)

}

@Observable
class DeviceModel: Identifiable, Equatable {

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
    //       decouple it from some of the logic around device model creation itself (we're currently having to inject
    //       more state than we need.)
    static func initialize(applicationModel: ApplicationModel,
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
                let fileServer = FileServer()
                let remoteCommandServicesClient = RemoteCommandServicesClient()

                // 1) Perform a drive listing. We know we can always safely do this.
                try cancellationToken.checkCancellation()
                let drives = try fileServer.drivesSync()

                // 2) Get the internal drive.
                guard let internalDrive = drives.first(where: { $0.driveAttributes.contains(.internal) }) else {
                    throw PLPToolsError.driveNotReady
                }

                // 3) Infer that we're talking to an EPOC16 device by the presence of a RAM-drive labeled M.
                try cancellationToken.checkCancellation()
                let epoc16 = internalDrive.drive == "M"

                // 3) If we're EPOC16, we need to ensure the RPCS server is installed on the Psion, copying it if not.
                try cancellationToken.checkCancellation()
                if try (epoc16 && !fileServer.exists(path: "M:\\SYS$RPCS.IMG")) {
                    let rpcsServer = Bundle.main.url(forResource: "SYS$RPCS", withExtension: ".IMG")!
                    try fileServer.copyFileSync(fromLocalPath: rpcsServer.path, toRemotePath: "M:\\SYS$RPCS.IMG") { _, _ in return .continue }
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
                let deviceModel = DeviceModel(applicationModel: applicationModel,
                                              fileServer: fileServer,
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

    @MainActor var isCapturingScreenshot: Bool = false

    var id: UUID {
        return deviceConfiguration.id
    }

    var canCaptureScreenshot: Bool {
        switch machineType {
        case .unknown, .pc, .mc, .hc, .winC:
            return false
        case .series3, .series3acmx, .workabout, .siena, .series3c:
            return false
        case .series5:
            return true
        }
    }

    var platform: Platform {
        if machineType.isEpoc32 {
            return .epoc32
        } else {
            return .epoc16
        }
    }

    var installDirectory: String? {
        switch machineType {
        case .unknown, .pc, .mc, .hc, .winC:
            return nil
        case .series3, .series3acmx, .workabout, .siena, .series3c:
            return .epoc16InstallDirectory
        case .series5:
            return .epoc32InstallDirectory
        }
    }

    @ObservationIgnored
    private weak var applicationModel: ApplicationModel?

    @ObservationIgnored
    weak var delegate: DeviceModelDelegate?

    let fileServer: FileServer
    let remoteCommandServicesClient: RemoteCommandServicesClient

    let deviceConfiguration: DeviceConfiguration
    let machineType: RemoteCommandServicesClient.MachineType
    let machineInfo: RemoteCommandServicesClient.MachineInfo?
    let drives: [FileServer.DriveInfo]
    let internalDrive: FileServer.DriveInfo

    private let workQueue = DispatchQueue(label: "DeviceModel.workQueue")

    private init(applicationModel: ApplicationModel,
                 fileServer: FileServer,
                 remoteCommandServicesClient: RemoteCommandServicesClient,
                 deviceConfiguration: DeviceConfiguration,
                 machineType: RemoteCommandServicesClient.MachineType,
                 machineInfo: RemoteCommandServicesClient.MachineInfo?,
                 drives: [FileServer.DriveInfo],
                 internalDrive: FileServer.DriveInfo) {
        self.applicationModel = applicationModel
        self.fileServer = fileServer
        self.remoteCommandServicesClient = remoteCommandServicesClient
        self.deviceConfiguration = deviceConfiguration
        self.machineType = machineType
        self.machineInfo = machineInfo
        self.drives = drives
        self.internalDrive = internalDrive
    }

    private func runInBackground(perform: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try perform()
            } catch {
                print("Failed to perform background operation with error \(error).")
            }
        }
    }

    static let backupNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        dateFormatter.timeZone = .gmt
        return dateFormatter
    }()

    // TODO: Accept a configuration and drives to back up.
    func backup(progress: Progress = Progress(),
                cancellationToken: CancellationToken = CancellationToken()) throws -> Backup {
        dispatchPrecondition(condition: .notOnQueue(.main))  // Not sure we care.

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
        let backupURL = fileManager.temporaryURL(isDirectory: true)
        defer { try? FileManager.default.removeItem(at: backupURL) }

        // TODO: Quit running apps.

        let files = try fileServer.dirSync(path: internalDrive.path, recursive: true)
        progress.totalUnitCount = Int64(files.count)
        progress.localizedDescription = "Copying files..."

        try cancellationToken.checkCancellation()
        let driveBackupURL = backupURL.appendingPathComponent(internalDrive.drive, isDirectory: true)
        for file in files {
            guard file.path.hasPrefix(internalDrive.path) else {
                throw PLPToolsError.invalidFileName
            }
            let relativePath = String(file.path.dropFirst(3))
            let destinationURL = driveBackupURL.appendingPathComponents(relativePath.windowsPathComponents)

            // Create the destination directory, or copy the file.
            progress.localizedAdditionalDescription = file.path
            if file.path.isWindowsDirectory {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                progress.completedUnitCount += 1
            } else {
                let copyProgress = Progress(totalUnitCount: Int64(file.size))
                progress.addChild(copyProgress, withPendingUnitCount: 1)

                try fileServer.copyFileSync(fromRemotePath: file.path, toLocalPath: destinationURL.path) { current, total in
                    copyProgress.completedUnitCount = Int64(current)
                    copyProgress.totalUnitCount = Int64(total)
                    return cancellationToken.isCancelled ? .cancel : .continue
                }
            }

            // Check to see if we've been cancelled.
            try cancellationToken.checkCancellation()
        }

        // Write a manifest.
        // We should use NCP_GET_UNIQUE_ID to include drive identifiers when we support removable drives.
        try cancellationToken.checkCancellation()
        let drive = BackupManifest.Drive(drive: internalDrive.drive,
                                         mediaType: internalDrive.mediaType,
                                         driveAttributes: internalDrive.driveAttributes,
                                         name: internalDrive.name)
        let manifest = BackupManifest(device: deviceConfiguration, date: .now, drives: [drive])
        try manifest.write(to: backupURL.appending(path: String.manifestFilename))

        // Move the backup to the final destination.
        try fileManager.moveItem(at: backupURL, to: destinationURL)
        let backup = Backup(manifest: manifest, url: destinationURL)

        // Notify our delegate.
        DispatchQueue.main.async {
            self.delegate?.deviceModel(deviceModel: self, didFinishBackup: backup)
        }

        return backup
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

        runInBackground { [transfersModel] in

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
            try fileServer.rename(from: .screenshotPath, to: screenshotPath)

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
