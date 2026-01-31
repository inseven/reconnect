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

fileprivate struct LayoutMetrics {
    static let paddingBottom = 16.0
}

struct PreviewSection<Content: View, Header: View>: View {

    let content: Content
    let header: Header

    init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.content = content()
        self.header = header()
    }

    var body: some View {
        VStack {
            header
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            content
        }
        .padding(.bottom, LayoutMetrics.paddingBottom)
        .frame(maxWidth: .infinity)
    }

}

extension PreviewSection where Header == EmptyView {

    init(@ViewBuilder content: () -> Content) {
        self.init(content: content, header: { EmptyView() })
    }

}
