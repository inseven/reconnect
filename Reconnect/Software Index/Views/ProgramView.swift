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

@Observable
class ProgramViewModel: ParentNavigable {

    let canNavigateToParent = true

    private let navigationModel: NavigationModel

    init(navigationModel: NavigationModel) {
        self.navigationModel = navigationModel
    }

    func navigateToParent() {
        self.navigationModel.navigate(to: .softwareIndex)
    }

}

struct ProgramView: View {

    @EnvironmentObject private var libraryModel: LibraryModel

    @State private var programViewModel: ProgramViewModel

    let program: Program

    init(navigationModel: NavigationModel, program: Program) {
        _programViewModel = State(initialValue: ProgramViewModel(navigationModel: navigationModel))
        self.program = program
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
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
                }
                if let description = program.description {
                    Text(description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("Releases")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(program.versions) { version in
                    Section {
                        ForEach(version.variants) { variant in
                            ForEach(variant.items, id: \.uniqueId) { item in
                                HStack(alignment: .center) {
                                    IconView(url: item.iconURL)
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                        Text(String(item.sha256.prefix(8)))
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .monospaced()
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
                                Divider()
                            }
                        }
                    } header: {
                        Text(version.id)
                            .font(.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(32)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .navigationTitle(program.name)
        .optionalNavigationSubtitle(program.subtitle)
        .focusedSceneObject(ParentNavigableProxy(programViewModel))
    }

}
