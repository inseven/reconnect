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

struct DetailsSection<Content: View, Header: View, Footer: View>: View {

    let content: Content
    let header: Header
    let footer: Footer

    init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header, @ViewBuilder footer: () -> Footer) {
        self.content = content()
        self.header = header()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading) {
            header
                .font(.title)
            VStack {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .modifier(DetailsGroupBackground())
            footer
        }
    }

}

extension DetailsSection where Header == Text, Footer == EmptyView {

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        } footer: {
            EmptyView()
        }
    }

    @_disfavoredOverload
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        } footer: {
            EmptyView()
        }
    }

}

extension DetailsSection where Footer == EmptyView {

    init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.init(content: content, header: header) {
            EmptyView()
        }
    }

}
