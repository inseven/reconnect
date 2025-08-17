// Copyright (c) 2024-2025 Jason Morley
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

@Observable
class ProgramViewModel: ParentNavigable {

    let canNavigateToParent = true

    private let navigationHistory: NavigationHistory

    init(navigationHistory: NavigationHistory) {
        self.navigationHistory = navigationHistory
    }

    func navigateToParent() {
        self.navigationHistory.navigate(.softwareIndex)
    }

}

struct ProgramView: View {

    @EnvironmentObject private var libraryModel: LibraryModel

    @State private var programViewModel: ProgramViewModel

    let program: Program

    init(navigationHistory: NavigationHistory, program: Program) {
        _programViewModel = State(initialValue: ProgramViewModel(navigationHistory: navigationHistory))
        self.program = program
    }

    var body: some View {
        List {
            if !(program.screenshots ?? []).isEmpty {
                Section {
                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .bottom) {
                            ForEach(program.screenshots ?? [], id: \.path) { screenshot in
                                AsyncImage(url: URL.softwareIndexAPIV1.appendingPathComponent(screenshot.path)) { image in
                                    image
                                        .resizable()
                                        .frame(width: CGFloat(screenshot.width), height: CGFloat(screenshot.height))
                                        .transition(.opacity.animation(.easeInOut))
                                } placeholder: {
                                    Rectangle()
                                        .fill(.tertiary)
                                        .frame(width: CGFloat(screenshot.width), height: CGFloat(screenshot.height))
                                        .transition(.opacity.animation(.easeInOut))
                                }
                                .border(.tertiary)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
                .padding()
            }
            if let description = program.description {
                Text(description)
                    .padding()
            }
            ForEach(program.versions) { version in
                Section(version.id) {
                    ForEach(version.variants) { variant in
                        ForEach(variant.items) { item in
                            HStack(alignment: .center) {
                                IconView(url: item.iconURL)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    Text(item.referenceString)
                                        .font(.footnote)
                                }
                                Spacer()
                                Text(item.size.formatted(.byteCount(style: .file)))
                                    .foregroundStyle(.secondary)
                                if let task = libraryModel.downloads[item.downloadURL] {
                                    HStack {
                                        ProgressView(task.progress)
                                            .progressViewStyle(.unadornedCircular)
                                            .controlSize(.small)
                                        Button("Cancel") {
                                            libraryModel.downloads[item.downloadURL]?.cancel()
                                        }
                                    }
                                } else {
                                    Button {
                                        libraryModel.download(item)
                                    } label: {
                                        Text("Install")
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .listStyle(.plain)
        .navigationTitle(program.name)
        .optionalNavigationSubtitle(program.subtitle)
        .focusedSceneObject(ParentNavigableProxy(programViewModel))
    }

}
