// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024 Jason Morley
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

@MainActor
struct InstallerView: View {

    @Environment(\.closeWindow) private var closeWindow

    @State var installerModel: InstallerModel

    init(installer: InstallerDocument) {
        _installerModel = State(initialValue: InstallerModel(installer))
    }

    var body: some View {
        VStack {
            switch installerModel.page {
            case .initial:
                Text("Intaller")
                Button("Install") {
                    installerModel.run()
                }
            case .query(let query):
                Text(query.text)
                Divider()
                HStack {
                    switch query.type {
                    case .Continue:
                        Button("Continue") {
                            query.continue(true)
                        }
                    case .Skip, .Abort:
                        Button("Yes") {
                            query.continue(true)
                        }
                        Button("No") {
                            query.continue(false)
                        }
                    case .Exit:
                        Button("Exit") {
                            query.continue(true)
                        }
                    }
                }
            case .complete:
                Text("Success")
                Divider()
                HStack {
                    Button("Done") {
                        closeWindow()
                    }
                }
            case .error(let error):
                Text("Error")
                Text(error.localizedDescription)
                Divider()
                HStack {
                    Button("Done") {
                        closeWindow()
                    }
                }
            }
        }
    }

}
