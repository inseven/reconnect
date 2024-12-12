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

import Interact

struct TransferRow: View {

    let transfer: Transfer
    
    var image: some View {
        switch transfer.item {
        case .local:
            Image(.fileUnknown16)
                .interpolation(.none)
                .resizable()
                .frame(width: 32, height: 32)
        case .remote(let file):
            Image(file.fileType.image)
                .interpolation(.none)
                .resizable()
                .frame(width: 32, height: 32)
        }
    }
    
    var statusText: String {
        switch transfer.status {
        case .waiting:
            return "Waiting to start…"
        case .active(let progress):
            return progress.formatted()
        case .complete:
            return "Complete"
        case .cancelled:
            return "Cancelled"
        case .failed(let error):
            return error.localizedDescription
        }

    }

    var body: some View {
        HStack(spacing: 16.0) {
            
            self.image
            
            VStack(alignment: .leading, spacing: 0) {

                Text(transfer.item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .horizontalSpace(.trailing)

                switch transfer.status {
                case .waiting:
                    ProgressView(value: 0)
                        .controlSize(.small)
                case .active(let progress):
                    ProgressView(value: progress)
                        .controlSize(.small)
                case .complete, .cancelled, .failed:
                    EmptyView()
                }

                Text(statusText)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .font(.callout)

            }

            switch transfer.status {
            case .waiting, .active:
                Button {
                    transfer.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            case .complete(let url):
                if let url {
                    Button {
                        Application.reveal(url)
                    } label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                    }
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            case .cancelled, .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
            
        }
        .padding()
    }

}
