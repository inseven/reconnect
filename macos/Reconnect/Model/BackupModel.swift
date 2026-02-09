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

        // TODO: Query for the backup configuration.

        let progress = Progress()
        let cancellationToken = CancellationToken()

        // Show the progress page.
        // Since this observes the progress object we've injected in, we don't need to do anything to ensure it updates.
        DispatchQueue.main.sync {
            self.page = .progress(progress, cancellationToken)
        }

        // Perform the backup.
        _ = try deviceModel.backUp(progress: progress, cancellationToken: cancellationToken)

        // Show complete page.
        DispatchQueue.main.sync {
            self.page = .complete
        }
    }

    func stop() {

    }

}
