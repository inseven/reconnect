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
class RestoreViewModel: Runnable {

    struct DeviceQuery: Identifiable {

        let id = UUID()

        let backup: Backup
        private let completion: (Result<DeviceModel.ID, Error>) -> Void

        init(backup: Backup, completion: @escaping (Result<DeviceModel.ID, Error>) -> Void) {
            self.backup = backup
            self.completion = completion
        }

        func `continue`(deviceId: DeviceModel.ID) {
            completion(.success(deviceId))
        }

        func cancel() {
            completion(.failure(ReconnectError.cancelled))
        }

    }

    struct DriveQuery: Identifiable {

        let id = UUID()

        let drives: [BackupManifest.Drive]
        let availableDrives: [FileServer.DriveInfo]
        let platform: Platform
        private let completion: (Result<Set<BackupManifest.Drive>, Error>) -> Void

        init(drives: [BackupManifest.Drive],
             availableDrives: [FileServer.DriveInfo],
             platform: Platform,
             completion: @escaping (Result<Set<BackupManifest.Drive>, Error>) -> Void) {
            self.drives = drives
            self.availableDrives = availableDrives
            self.platform = platform
            self.completion = completion
        }

        func `continue`(drives: Set<BackupManifest.Drive>) {
            completion(.success(drives))
        }

        func cancel() {
            completion(.failure(ReconnectError.cancelled))
        }

    }

    enum Page {
        case loading
        case deviceQuery(DeviceQuery)
        case driveQuery(DriveQuery)
        case progress(Progress, CancellationToken)
        case error(Error)
        case complete
    }

    private let applicationModel: ApplicationModel
    private let backup: Backup

    var page: Page = .loading

    init(applicationModel: ApplicationModel, backup: Backup) {
        self.applicationModel = applicationModel
        self.backup = backup
    }

    func start() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try self.restore()
            } catch {
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }

    private func restore() throws {
        dispatchPrecondition(condition: .notOnQueue(.main))

        // Check which device to restore to.
        let deviceIdFuture = UnsafeFuture<UUID, Error>()
        let deviceQuery = DeviceQuery(backup: backup) { result in
            deviceIdFuture.resolve(result: result)
        }
        DispatchQueue.main.async {
            self.page = .deviceQuery(deviceQuery)
        }
        let deviceId = try deviceIdFuture.get()
        let deviceModel = DispatchQueue.main.sync {
            return applicationModel.deviceModel(for: deviceId)
        }
        guard let deviceModel else {
            throw PLPToolsError.E_PSI_FILE_DISC
        }

        // Check which drives to restore.
        let drivesFuture = UnsafeFuture<Set<BackupManifest.Drive>, Error>()
        let driveQuery = DriveQuery(drives: backup.manifest.drives,
                                    availableDrives: deviceModel.drives,
                                    platform: backup.manifest.platform ?? .epoc32) { result in
            drivesFuture.resolve(result: result)
        }
        DispatchQueue.main.async {
            self.page = .driveQuery(driveQuery)
        }
        let drives = try drivesFuture.get()

        // Show the progress page.
        let progress = Progress()
        let cancellationToken = CancellationToken()
        DispatchQueue.main.sync {
            self.page = .progress(progress, cancellationToken)
        }

        // Perform the restore.
        _ = try deviceModel.restore(backup: backup,
                                    drives: drives,
                                    progress: progress,
                                    cancellationToken: cancellationToken)

        // Show complete page.
        DispatchQueue.main.sync {
            self.page = .complete
        }
    }

    func stop() {

    }

}
