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

@MainActor
struct LanguageQueryInstallerPage: View {

    @State var selection: String

    let query: InstallerModel.LanguageQuery

    init(query: InstallerModel.LanguageQuery) {
        self.query = query
        self.selection = try! Locale.selectLanguage(query.languages)
    }

    var body: some View {
        InstallerPage {
            List(selection: $selection) {
                ForEach(query.languages, id: \.self) { language in
                    Text(NSLocalizedString(language, comment: language))
                }
            }
        } actions: {
            Button("Cancel", role: .destructive) {
                query.resume(.failure(.userCancelled))
            }
            Button("Continue") {
                query.resume(.success(selection))
            }
            .keyboardShortcut(.defaultAction)
        }
    }

}
