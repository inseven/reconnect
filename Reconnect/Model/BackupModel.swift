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

    // Synchronzized on the main queue.
    var page: Page = .loading

    private let applicationModel: ApplicationModel
    private let deviceModel: DeviceModel

    init(applicationModel: ApplicationModel, deviceModel: DeviceModel) {
        self.applicationModel = applicationModel
        self.deviceModel = deviceModel
    }

    func start() {
        guard let deviceModel = applicationModel.devices.first else {
            // TODO: Handle null device model.
            return
        }
        let backupsURL = applicationModel.backupsURL  // TODO: This could, and should, be on the device model.
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

        // TODO: Query for the backup configuration.


        let progress = Progress()
        let cancellationToken = CancellationToken()

        // Show the progress page.
        // Since this observes the progress object we've injected in, we don't need to do anything to ensure it updates.
        DispatchQueue.main.sync {
            self.page = .progress(progress, cancellationToken)
        }

        // Perform the backup.
        // TODO: This should probably work on a queue itself to stop us running two at once, or gate other access, etc.
        try deviceModel.backup(to: backupURL,
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
