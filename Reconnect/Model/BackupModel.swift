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
import Interact

import ReconnectCore

@Observable
class BackupModel: Runnable {

    enum Page {
        case loading
        case progress(Progress, CancellationToken)
        case error(Error)
        case complete
    }

    // Synchronized on the main queue.
    var page: Page = .loading
    var deviceModel: DeviceModel?

    private let applicationModel: ApplicationModel

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
    }

    func start() {
        guard let deviceModel = applicationModel.devices.first else {
            // TODO: Handle null device model.
            return
        }
        self.deviceModel = deviceModel
        let backupsURL = applicationModel.backupsURL
        DispatchQueue.global(qos: .userInteractive).async {

            let deviceBackupsURL = backupsURL.appendingPathComponent(deviceModel.id.uuidString, isDirectory: true)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
            dateFormatter.timeZone = .gmt
            let basename = dateFormatter.string(from: Date())

            let backupURL = deviceBackupsURL.appendingPathComponent(basename, isDirectory: true)

            do {
                try self.backup(to: backupURL)
            } catch {

                // Clean up.
                try? FileManager.default.removeItem(at: backupURL)

                // Report the error.
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }
    private func backup(to backupURL: URL) throws {
        dispatchPrecondition(condition: .notOnQueue(.main))

        // Determine which device we're using and get its file server.
        // TODO: Tidy up the file server life cyle:
        //       - How many file servers can I use here?
        //       - Can I pool them?
        //       - How do I make sure they're not owned outside of the device model?
        guard let deviceModel = self.deviceModel else {
            throw PLPToolsError.unitDisconnected
        }
        let fileServer = deviceModel.fileServer

        // TODO: Show backup configuration with drive picker and incremental backup options.

        // TODO: Show loading files screen

        let drives = try fileServer.drivesSync()
        guard let internalDrive = drives.first(where: { driveInfo in
            return driveInfo.mediaType == .ram
        }) else {
            throw PLPToolsError.driveNotReady
        }

        let progress = Progress()
        let cancellationToken = CancellationToken()

        DispatchQueue.main.sync {
            self.page = .progress(progress, cancellationToken)
        }

        let files = try fileServer.dirSync(path: internalDrive.path, recursive: true)
        progress.totalUnitCount = Int64(files.count)
        progress.localizedDescription = "Copying files..."

        try cancellationToken.checkCancellation()

        // TODO: Convenience for updating callbacks.

        // TODO: Quit apps before launching.

        // TODO: Show confirmation.

        let fileManager = FileManager.default

        DispatchQueue.main.sync {
            self.page = .progress(progress, cancellationToken)
        }

        let driveBackupURL = backupURL.appendingPathComponent(internalDrive.drive, isDirectory: true)
        for file in files {
            guard file.path.hasPrefix(internalDrive.path) else {
                return
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
                    DispatchQueue.main.async {
                        self.page = .progress(progress, cancellationToken)
                    }
                    return cancellationToken.isCancelled ? .cancel : .continue
                }
            }

            // Check to see if we've been cancelled.
            try cancellationToken.checkCancellation()

            // Show final file progress.
            DispatchQueue.main.sync {
                self.page = .progress(progress, cancellationToken)
            }

        }

        // Show complete page.
        DispatchQueue.main.sync {
            self.page = .complete
        }

    }

    func stop() {

    }

}
