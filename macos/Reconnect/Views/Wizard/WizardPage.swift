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

fileprivate struct LayoutMetrics {
    static let minWidth: CGFloat = 600
    static let minHeight: CGFloat = 400
}

@MainActor
struct WizardPage<Content: View, Actions: View>: View {

    let title: Text?
    let content: Content
    let actions: Actions

    init(_ title: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        if let title {
            self.title = Text(title)
        } else {
            self.title = nil
        }
        self.content = content()
        self.actions = actions()
    }

    @_disfavoredOverload
    init(_ title: String? = nil, @ViewBuilder content: () -> Content, @ViewBuilder actions: () -> Actions) {
        if let title {
            self.title = Text(title)
        } else {
            self.title = nil
        }
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title {
                HStack {
                    title
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
        .frame(minWidth: LayoutMetrics.minWidth, minHeight: LayoutMetrics.minHeight)
    }

}
