// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024-2025 Jason Morley
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

struct ProgramManagerView: View {

    @Environment(ApplicationModel.self) private var applicationModel

    @State private var programManagerModel: ProgramManagerModel

    init(deviceModel: DeviceModel) {
        _programManagerModel = State(initialValue: ProgramManagerModel(deviceModel: deviceModel))
    }

    var body: some View {
        VStack(spacing: 0) {
            if case ProgramManagerModel.State.checkingInstalledPackages(let progress) = programManagerModel.state {
                VStack {
                    Text("Checking installed packages...")
                    ProgressView(value: progress.fractionCompleted)
                }
                .padding()
                .frame(maxWidth: InstallerView.LayoutMetrics.maximumContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(of: ProgramManagerModel.ProgramDetails.self) {
                    TableColumn("Program") { programDetails in
                        Text(programDetails.sis.localizedDisplayName)
                    }
                    TableColumn("Version") { programDetails in
                        Text("\(programDetails.sis.version.major).\(programDetails.sis.version.minor)")
                    }
                    TableColumn("") { programDetails in
                        Button("Remove") {
                            programManagerModel.remove(uid: programDetails.sis.uid)
                        }
                        .buttonStyle(.bordered)
                    }
                } rows: {
                    ForEach(programManagerModel.installedPrograms, id: \.self) { programDetails in
                        TableRow(programDetails)
                    }
                }
            }
        }
        .background(.textBackgroundColor)
        .disabled(!programManagerModel.isReady)
        .runs(programManagerModel)
    }

}
