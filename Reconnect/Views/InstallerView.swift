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

struct InstallerPage<Content: View, Actions: View>: View {

    let content: Content
    let actions: Actions

    init(@ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        ScrollView {
            content
        }
        .textSelection(.enabled)
        .padding()
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Spacer()
                    actions
                }
                .padding()
            }
        }
    }


}

@MainActor
struct InstallerView: View {

    @Environment(\.closeWindow) private var closeWindow

    @State var installerModel: InstallerModel

    init(installer: InstallerDocument) {
        _installerModel = State(initialValue: InstallerModel(installer))
    }

    var body: some View {
        switch installerModel.page {
        case .initial:
            InstallerPage {
                Text("Intaller")
            } actions: {
                Button("Install") {
                    installerModel.run()
                }
            }
        case .query(let query):
            InstallerPage {
                Text(query.text)
            } actions: {
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
        case .copy(let path, let progress):
            InstallerPage {
                Text("Writing '\(path)'...")
                ProgressView(value: progress)
            } actions: {
                Button("Cancel") {

                }
                .disabled(true)
            }
        case .complete:
            InstallerPage {
                Text("Success")
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
            } actions: {
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
