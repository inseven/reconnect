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

@MainActor
struct RestoreView: View {

    @Environment(\.closeWindow) private var closeWindow
    @Environment(\.window) private var window

    @State var restoreModel: RestoreViewModel

    private let applicationModel: ApplicationModel
    private let backup: Backup

    init(applicationModel: ApplicationModel, backup: Backup) {
        self.applicationModel = applicationModel
        self.backup = backup
        _restoreModel = State(initialValue: RestoreViewModel(applicationModel: applicationModel, backup: backup))
    }

    var body: some View {
        VStack(spacing: 0) {
            switch restoreModel.page {
            case .loading:
                WizardPage {
                    ProgressView()
                } actions: {
                    Button("Cancel", role: .destructive) {}
                        .disabled(true)
                    Button("Continue") {}
                        .keyboardShortcut(.defaultAction)
                        .disabled(true)
                }
            case .deviceQuery(let deviceQuery):
                RestoreDevicePickerPage(applicationModel: applicationModel, deviceQuery: deviceQuery)
            case .driveQuery(let driveQuery):
                RestoreDrivePickerPage(driveQuery: driveQuery)
            case .progress(let progress, let cancellationToken):
                WizardProgressPage("rest", progress: progress, cancellationToken: cancellationToken)
            case .complete:
                WizardCompletePage("Restore Complete")
            case .error(let error):
                WizardErrorPage(error: error)
            }
        }
        .runs(restoreModel)
    }

}
