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

struct TransfersButton: View {

    let transfers: Transfers

    @State var showPopover = false

    var body: some View {
        @Bindable var transfers = transfers
        Button {
            showPopover = true
        } label: {
            Label {
                Text("Transfers")
            } icon: {
                if transfers.active {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .disabled(transfers.transfers.isEmpty)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                Text("Transfers")
                    .padding()
                Divider()
                List(selection: $transfers.selection) {
                    ForEach(transfers.transfers) { transfer in
                        TransferRow(transfer: transfer)
                    }
                }
                .scrollContentBackground(.hidden)
                .frame(minHeight: 300)
            }
            .frame(minWidth: 400)
            .background(.thinMaterial)
        }
    }

}
