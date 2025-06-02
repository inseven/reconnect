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
struct InstallerPage<Content: View, Actions: View>: View {

    let title: LocalizedStringKey?
    let content: Content
    let actions: Actions

    init(_ title: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                }
                .padding()
                Divider()
            }
            content
                .textSelection(.enabled)
                .frame(maxHeight: .infinity)
            Divider()
            HStack {
                Spacer()
                actions
            }
            .padding()
        }
    }

}
