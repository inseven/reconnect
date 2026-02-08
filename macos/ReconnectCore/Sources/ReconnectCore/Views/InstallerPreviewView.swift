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

import OpoLuaCore

public struct InstallerPreviewView: View {

    let file: Sis.File

    public init(file: Sis.File) {
        self.file = file
    }

    public var body: some View {
        VStack(alignment: .center) {

            PreviewSection {
                if file.version != .zero {
                    Text(file.version.description)
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                if file.uid != 0 {
                    Text(String(format: "0x%08X", file.uid))
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
            } header: {
                Text(file.localizedDisplayName)
                    .font(.title)
                    .foregroundStyle(.primary)
            }

            PreviewSection {
                Text(file.target.localizedStringResource)
            } header: {
                Text("Platform")
            }

            PreviewSection {
                ForEach(file.languages, id: \.self) { language in
                    Text(NSLocalizedString(language, comment: language))
                }
            } header: {
                Text("Languages")
            }

            Spacer()
        }
        .scenePadding()
        .background(Color(nsColor: .textBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

#Preview("PsiMail Internet - EPOC16") {
    InstallerPreviewView(file: Sis.File(target: .epoc16,
                                        name: ["en-GB": "PsiMail Internet"],
                                        uid: 0x00000000,
                                        version: .zero,
                                        languages: ["en_GB"]))
    .background(Color.pink)
}

#Preview("Nezumi - EPOC32") {
    InstallerPreviewView(file: Sis.File(target: .epoc32,
                                        name: ["en-GB": "Nezumi"],
                                        uid: 0x100092c8,
                                        version: Sis.Version(major: 1, minor: 23),
                                        languages: ["en_GB"]))
    .background(Color.pink)
}
