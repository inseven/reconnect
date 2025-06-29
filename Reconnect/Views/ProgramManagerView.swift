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

    @State var programManagerModel = ProgramManagerModel()

    var body: some View {
        HStack {
            switch programManagerModel.state {
            case .checkingInstalledPackages(let progress):
                ProgressView(value: progress)
            case .ready:
                List {
                    ForEach(programManagerModel.installedPrograms, id: \.path) { program in
                        Text(program.sis.localizedDisplayNameAndVersion)
                    }
                }
            case .error(let error):
                Text(error.localizedDescription)
            }
            VStack {
                Button("Remove") {

                }
                Button("Add...") {

                }
                Spacer()
            }
        }
        .runs(programManagerModel)
        .frame(width: 800, height: 600)
    }

}
