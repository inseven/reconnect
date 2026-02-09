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

struct ProgramsView: View {

    @Environment(NavigationModel<BrowserSection>.self) private var navigationModel

    @EnvironmentObject private var libraryModel: LibraryModel

    var body: some View {
        VStack {
            if libraryModel.isLoading {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 0) {
                        ForEach(libraryModel.filteredPrograms) { program in
                            Button {
                                navigationModel.navigate(to: .program(program))
                            } label: {
                                ItemView(imageURL: program.iconURL,
                                         title: program.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .searchable(text: $libraryModel.searchFilter)
        .navigationTitle("Psion Software Index")
        .optionalNavigationSubtitle(libraryModel.isLoading ? nil : "\(libraryModel.filteredPrograms.count) Programs")
        .onAppear {
            libraryModel.start()
        }
        .environmentObject(libraryModel)
        .focusedSceneObject(RefreshableProxy(libraryModel))
    }

}
