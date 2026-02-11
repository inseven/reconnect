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

import ReconnectCore

struct BackupView: View {

    @Environment(\.closeWindow) private var closeWindow
    @Environment(\.window) private var window

    @State private var backupModel: BackupViewModel

    private var applicationModel: ApplicationModel

    init(applicationModel: ApplicationModel, deviceModel: DeviceModel) {
        self.applicationModel = applicationModel
        _backupModel = State(initialValue: BackupViewModel(applicationModel: applicationModel, deviceModel: deviceModel))
    }

    var body: some View {
        VStack(spacing: 0) {
            switch backupModel.page {
            case .loading:
                WizardPage {
                    VStack {
                        ProgressView()
                    }
                } actions: {
                    Button("Continue") {}
                        .keyboardShortcut(.defaultAction)
                        .disabled(true)
                }
            case .selectDrives(let driveQuery):
                BackupDrivePickerPage(driveQuery: driveQuery)
            case .progress(let progress, let cancellationToken):
                WizardPage {
                    VStack {
                        ProgressAnimation("back")
                        ProgressView(progress)
                    }
                    .padding()
                    .frame(maxWidth: WizardLayoutMetrics.maximumContentWidth)
                } actions: {
                    Button("Cancel", role: .destructive) {
                        cancellationToken.cancel()
                    }
                    .disabled(cancellationToken.isCancelled)
                }

            case .error(let error):
                WizardErrorPage(error: error)
            case .complete:
                WizardCompletePage("Backup Complete")

            }
        }
        .onAppear {
            window.title = "Backup - \(backupModel.name)"
        }
        .runs(backupModel)
    }

}
