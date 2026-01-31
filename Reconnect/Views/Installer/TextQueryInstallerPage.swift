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

@MainActor
struct TextQueryInstallerPage: View {

    let query: InstallerModel.TextQuery

    var body: some View {
        InstallerPage(query.sis.localizedDisplayNameAndVersion) {
            ScrollView {
                Text(query.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
        } actions: {
            switch query.type {
            case .continue:
                Button("Continue") {
                    query.resume(true)
                }
                .keyboardShortcut(.defaultAction)
            case .skip, .abort:
                Button("No") {
                    query.resume(false)
                }
                Button("Yes") {
                    query.resume(true)
                }
                .keyboardShortcut(.defaultAction)
            case .exit:
                Button("Exit") {
                    query.resume(true)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

}
