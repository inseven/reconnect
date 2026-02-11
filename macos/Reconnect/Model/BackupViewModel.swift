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
class BackupViewModel: Runnable {

    struct DriveQuery: Identifiable {

        let id = UUID()
        let drives: [FileServer.DriveInfo]
        let defaultSelection: Set<FileServer.DriveInfo>
        let platform: Platform

        private let completion: (Result<Set<FileServer.DriveInfo>, Error>) -> Void

        init(drives: [FileServer.DriveInfo],
             defaultSelection: Set<FileServer.DriveInfo>,
             platform: Platform,
             completion: @escaping (Result<Set<FileServer.DriveInfo>, Error>) -> Void) {
            self.drives = drives
            self.defaultSelection = defaultSelection
            self.platform = platform
            self.completion = completion
        }

        func `continue`(drives: Set<FileServer.DriveInfo>) {
            completion(.success(drives))
        }

        func cancel() {
            completion(.failure(ReconnectError.cancelled))
        }

    }

    enum Page {
        case loading
        case selectDrives(DriveQuery)
        case progress(Progress, CancellationToken)
        case error(Error)
        case complete
    }

    // Synchronzized on the main queue.
    var page: Page = .loading

    private let applicationModel: ApplicationModel
    private let deviceModel: DeviceModel

    var name: String {
        return deviceModel.deviceConfiguration.name
    }

    init(applicationModel: ApplicationModel, deviceModel: DeviceModel) {
        self.applicationModel = applicationModel
        self.deviceModel = deviceModel
    }

    func start() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try self.backup()
            } catch {
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }

    private func backup() throws {
        dispatchPrecondition(condition: .notOnQueue(.main))

        // Show the drive picker.
        let sem = DispatchSemaphore(value: 0)
        var result: Result<Set<FileServer.DriveInfo>, Error> = .failure(ReconnectError.cancelled)
        let driveQuery = DriveQuery(drives: deviceModel.drives,
                                    defaultSelection: [deviceModel.internalDrive],
                                    platform: deviceModel.platform) { completionResult in
            result = completionResult
            sem.signal()
        }
        DispatchQueue.main.sync {
            self.page = .selectDrives(driveQuery)
        }
        sem.wait()
        let drives = try result.get()

        // Show the progress page.
        // Since this observes the progress object we've injected in, we don't need to do anything to ensure it updates.
        let progress = Progress()
        let cancellationToken = CancellationToken()
        DispatchQueue.main.sync {
            self.page = .progress(progress, cancellationToken)
        }

        // Perform the backup.
        _ = try deviceModel.backUp(drives: drives, progress: progress, cancellationToken: cancellationToken)

        // Show complete page.
        DispatchQueue.main.sync {
            self.page = .complete
        }
    }

    func stop() {

    }

}
