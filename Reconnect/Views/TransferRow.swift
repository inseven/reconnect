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

struct TransferRow: View {

    let transfer: Transfer

    var body: some View {
        VStack(alignment: .leading) {
            Text(transfer.title)
            switch transfer.status {
            case .waiting:
                Text("Waiting...")
                    .foregroundStyle(.secondary)
            case .active(let progress):
                HStack {
                    ProgressView(value: progress)
                    Button {
                        transfer.cancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            case .complete:
                Text("Complete!")
                    .foregroundStyle(.secondary)
            case .cancelled:
                Text("Cancelled")
            case .failed(let error):
                Text(String(describing: error))
                    .foregroundStyle(.secondary)
            }

        }
        .padding()
    }

}
