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

struct BackupDrivePickerPage: View {

    let driveQuery: BackupViewModel.DriveQuery

    @State var selectedDrives: Set<FileServer.DriveInfo>

    init(driveQuery: BackupViewModel.DriveQuery) {
        self.driveQuery = driveQuery
        _selectedDrives = State(initialValue: driveQuery.defaultSelection)
    }

    func binding(for drive: FileServer.DriveInfo) -> Binding<Bool> {
        return Binding {
            selectedDrives.contains(drive)
        } set: { isOn in
            if isOn {
                selectedDrives.insert(drive)
            } else {
                selectedDrives.remove(drive)
            }
        }
    }

    var body: some View {
        WizardPage {
            VStack(alignment: .leading) {
                Text("Select drives:")
                ForEach(driveQuery.drives) { drive in
                    Toggle(isOn: binding(for: drive)) {
                        Label(DisplayHelpers.displayNameForDrive(drive.drive, name: drive.name),
                              image: DisplayHelpers.imageForDrive(drive.drive,
                                                                  mediaType: drive.mediaType,
                                                                  platform: driveQuery.platform))
                    }
                }
            }
            .padding()
            .frame(maxWidth: WizardLayoutMetrics.maximumContentWidth)
        } actions: {
            Button("Cancel", role: .destructive) {
                driveQuery.cancel()
            }
            Button("Continue") {
                driveQuery.continue(drives: selectedDrives)
            }
            .keyboardShortcut(.defaultAction)
        }
    }

}
