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

struct TransfersView: View {

    private struct LayoutMetrics {
        static let width = 360.0
        static let minimumHeight = 300.0
        static let footerPadding = 8.0
    }

    @Environment(\.dismiss) private var dismiss

    @Environment(ApplicationModel.self) private var applicationModel

    private let transfersModel: TransfersModel

    init(transfersModel: TransfersModel) {
        self.transfersModel = transfersModel
    }

    var body: some View {
        @Bindable var applicationModel = applicationModel
        @Bindable var transfers = transfersModel
        List(selection: $transfers.selection) {
            ForEach(transfers.transfers) { transfer in
                TransferRow(transfer: transfer)
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Toggle("Convert Files", isOn: $applicationModel.convertFiles)
                    
                    Spacer()

                    Button("Clear") {
                        transfersModel.clear()
                        if transfersModel.transfers.isEmpty {
                            dismiss()
                        }
                    }
                    .disabled(transfersModel.transfers.isEmpty)
                }
                .padding(LayoutMetrics.footerPadding)
            }
            .background(.regularMaterial)
        }
        .frame(minHeight: LayoutMetrics.minimumHeight)
        .frame(width: LayoutMetrics.width)
    }

}
