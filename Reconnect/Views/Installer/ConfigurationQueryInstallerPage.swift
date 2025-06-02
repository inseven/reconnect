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

import OpoLua

@MainActor
struct ConfigurationQueryInstallerPage: View {

    @State var driveSelection: String = "C"
    @State var languageSelection: String

    let query: InstallerModel.ConfigurationQuery
    let languages: [String]

    init(query: InstallerModel.ConfigurationQuery) {
        self.query = query
        self.languages = query.installer.languages
        self.languageSelection = query.defaultLanguage
    }

    var body: some View {
        VStack(spacing: 0) {
            InstallerPage("Install '\(query.installer.localizedDisplayName)'?") {
                Form {
                    if languages.count > 1 {
                        LabeledContent("Language") {
                            Picker(selection: $languageSelection) {
                                ForEach(languages, id: \.self) { language in
                                    Text(NSLocalizedString(language, comment: language))
                                        .tag(language)
                                }
                            }
                        }
                    }
                    LabeledContent("Drive") {
                        Picker(selection: $driveSelection) {
                            ForEach(query.drives, id: \.drive) { driveInfo in
                                Text(driveInfo.drive)
                                    .tag(driveInfo.drive)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: InstallerView.LayoutMetrics.maximumContentWidth)
            } actions: {
                Button("Cancel", role: .destructive) {
                    query.resume(.userCancelled)
                }
                Button("Continue") {
                    query.resume(.install(languageSelection, driveSelection))
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

}
