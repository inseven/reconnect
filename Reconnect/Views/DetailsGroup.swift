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

struct DetailsGroup<Content: View, Label: View>: View {

    let content: Content
    let label: Label

    init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.content = content()
        self.label = label()
    }

    var body: some View {
        VStack(alignment: .leading) {
            label
                .font(.title)
            VStack {
                content
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.quinary)
            .border(.quaternary)  // TODO: ROUND THIS!
        }
    }

}

extension DetailsGroup where Label == Text {

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        }
    }

    @_disfavoredOverload
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        }
    }

}
