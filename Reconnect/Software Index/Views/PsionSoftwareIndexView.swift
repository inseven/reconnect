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

import Interact

class LibraryModelBlockDelegate: LibraryModelDelegate {

    let complete: (PsionSoftwareIndexView.Item?) -> Void

    init(complete: @escaping (PsionSoftwareIndexView.Item?) -> Void) {
        self.complete = complete
    }

    func libraryModelDidCancel(libraryModel: LibraryModel) {
        self.complete(nil)
    }

    func libraryModel(libraryModel: LibraryModel, didSelectItem item: PsionSoftwareIndexView.Item) {
        self.complete(item)
    }

}

public struct PsionSoftwareIndexView: View {

    public struct Item {

        public let sourceURL: URL
        public let url: URL

    }

    @StateObject var model: LibraryModel

    let delegate: LibraryModelBlockDelegate?

    init(model: LibraryModel) {
        _model = StateObject(wrappedValue: model)
        delegate = nil
    }

    public init(completion: @escaping (PsionSoftwareIndexView.Item?) -> Void) {
        self.delegate = LibraryModelBlockDelegate(complete: completion)
        let libraryModel = LibraryModel()
        _model = StateObject(wrappedValue: libraryModel)
        libraryModel.delegate = delegate
    }

    public var body: some View {
        NavigationStack {
            ProgramsView()
                .environmentObject(model)
        }
        .presents($model.error)
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600)
    }

}
