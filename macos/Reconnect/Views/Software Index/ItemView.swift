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

struct ItemView: View {

    let imageURL: URL?
    let title: String
    let subtitle: String?

    init(imageURL: URL?, title: String, subtitle: String? = nil) {
        self.imageURL = imageURL
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack {
            IconView(url: imageURL)
                .padding()
            VStack(alignment: .leading) {
                Spacer()
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Spacer()
                Divider()
            }
        }
        .contentShape(Rectangle())
    }

}
