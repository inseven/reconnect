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

    struct LayoutMetrics {
        static let symbolSize: CGFloat = 128.0
    }

    @Environment(\.closeWindow) private var closeWindow

    @State var installerModel: InstallerModel

    init(installer: InstallerDocument) {
        _installerModel = State(initialValue: InstallerModel(installer))
    }

    var body: some View {
        VStack {
            switch installerModel.page {
            case .loading:
                InstallerPage {
                    VStack {
                        ProgressView()
                    }
                } actions: {
                    Button("Continue") {

                    }
                    .disabled(true)
                }
            case .initial(let details):
                InstallerPage {
                    VStack {
                        Text(details.name)
                            .padding()
                        Text(details.version)
                            .padding()
                    }
                } actions: {
                    Button("Continue") {
                        installerModel.run()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            case .languageQuery(let query):
                LanguageInstallerPage(query: query)
            case .query(let query):
                InstallerPage {
                    ScrollView {
                        Text(query.text)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                } actions: {
                    switch query.type {
                    case .Continue:
                        Button("Continue") {
                            query.continue(true)
                        }
                        .keyboardShortcut(.defaultAction)
                    case .Skip, .Abort:
                        Button("No") {
                            query.continue(false)
                        }
                        Button("Yes") {
                            query.continue(true)
                        }
                        .keyboardShortcut(.defaultAction)
                    case .Exit:
                        Button("Exit") {
                            query.continue(true)
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            case .copy(let path, let progress):
                InstallerPage {
                    VStack {
                        Text(path)
                        ProgressView(value: progress)
                    }
                    .padding()
                } actions: {
                    Button("Cancel") {

                    }
                    .disabled(true)
                }
            case .complete:
                InstallerPage {
                    VStack {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: LayoutMetrics.symbolSize)
                            .foregroundStyle(.green)
                    }
                    .padding()
                } actions: {
                    Button("Done") {
                        closeWindow()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            case .error(let error):
                InstallerPage {
                    ScrollView {
                        Text("Error")
                        Text(error.localizedDescription)
                    }
                } actions: {
                    Button("Done") {
                        closeWindow()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .onAppear {
            installerModel.load()
        }
    }

}
