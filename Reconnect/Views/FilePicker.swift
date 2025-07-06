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

struct FilePickerOptions: OptionSet {
    let rawValue: Int
    static let canChooseFiles = Self(rawValue: 1 << 0)
    static let canChooseDirectories = Self(rawValue: 1 << 1)
    static let canCreateDirectories = Self(rawValue: 1 << 2)
}

struct FilePicker<Label: View>: View {

    let label: Label
    let options: FilePickerOptions

    @Binding var url: URL

    init(url: Binding<URL>, options: FilePickerOptions = [], @ViewBuilder label: () -> Label) {
        self.label = label()
        self.options = options
        _url = url
    }

    var body: some View {
        LabeledContent {
            HStack {
                Text(url.displayName)
                Button("Select...") {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = options.contains(.canChooseFiles)
                    openPanel.canChooseDirectories = options.contains(.canChooseDirectories)
                    openPanel.canCreateDirectories = options.contains(.canCreateDirectories)
                    openPanel.directoryURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
                    guard
                        openPanel.runModal() ==  NSApplication.ModalResponse.OK,
                        let url = openPanel.url
                    else {
                        return
                    }
                    self.url = url
                }
            }
        } label: {
            label
        }
    }

}

extension FilePicker where Label == Text {

    init(_ titleKey: LocalizedStringKey, url: Binding<URL>, options: FilePickerOptions = []) {
        self.label = Text(titleKey)
        self.options = options
        _url = url
    }

}
