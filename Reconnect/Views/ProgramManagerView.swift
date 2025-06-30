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

    @State private var programManagerModel = ProgramManagerModel()

    var body: some View {
        VStack(spacing: 0) {
            Table(of: ProgramManagerModel.ProgramDetails.self, selection: $programManagerModel.selection) {  // TODO: Wrong selection type?!
                TableColumn("Program") { programDetails in
                    Text(programDetails.sis.localizedDisplayName)
                }
                TableColumn("Version") { programDetails in
                    Text("\(programDetails.sis.version.major).\(programDetails.sis.version.minor)")  // TODO: As string??
                }
            } rows: {
                ForEach(programManagerModel.installedPrograms, id: \.self) { programDetails in
                    TableRow(programDetails)
                }
            }

            Divider()

            if case ProgramManagerModel.State.checkingInstalledPackages(let progress) = programManagerModel.state {
                HStack {
                    ProgressView(value: progress.fractionCompleted)
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                    Text("Updating...")
                }
                .foregroundStyle(.secondary)
                .padding()
            } else {
                Text("\(programManagerModel.installedPrograms.count) Programs")
                    .foregroundStyle(.secondary)
                    .padding()
            }

        }
        .toolbar {

            ToolbarItem {
                Button {
                    programManagerModel.reload()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            ToolbarItem {
                Button {
                    programManagerModel.remove()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(!programManagerModel.canRemove)
            }

            ToolbarItem {
                Button {
                    applicationModel.openInstaller()
                } label: {
                    Label("Add...", systemImage: "plus")
                }
            }

        }
        .disabled(!programManagerModel.isReady)
        .runs(programManagerModel)
        .frame(minWidth: 640, minHeight: 480)
    }

}
