// Copyright (c) 2024-2026 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import SwiftUI

struct ProgramsView: View {

    @Environment(ApplicationModel.self) private var applicationModel

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
                                applicationModel.navigate(to: .program(program))
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
