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

import Interact

struct TransferRow: View {

    struct LayoutMetrics {
        static let iconSize = 32.0
        static let horizontalSpacing = 16.0
    }

    let transfer: Transfer
    
    var image: some View {
        // We differentiate between complete and incomplete transfers to allow us to show thumbnails that correspond
        // with the final state of the tranfer---downloaded files will show their converted thumbnails where
        // appropriate, etc.
        VStack {
            switch transfer.status {
            case .complete(let details):
                switch transfer.item {
                case .local:
                    PixelImage(.fileUnknown16)
                case .remote(let file):
                    if let details {
                        switch details.reference {
                        case .local(let url):
                            ThumbnailView(url: url,
                                          size: CGSize(width: LayoutMetrics.iconSize, height: LayoutMetrics.iconSize))
                        case .remote(let directoryEntry):
                            PixelImage(directoryEntry.fileType.image)
                        }
                    } else {
                        PixelImage(file.fileType.image)
                    }
                }
            default:
                switch transfer.item {
                case .local:
                    PixelImage(.fileUnknown16)
                case .remote(let file):
                    PixelImage(file.fileType.image)
                }
            }
        }
        .frame(width: LayoutMetrics.iconSize, height: LayoutMetrics.iconSize)
    }

    var name: String {
        guard
            case .complete(let details) = transfer.status,
            let details
        else {
            return transfer.item.name
        }
        switch details.reference {
        case .local(let url):
            return url.lastPathComponent
        case .remote(let directoryEntry):
            return directoryEntry.name
        }
    }

    var statusText: String? {
        switch transfer.status {
        case .waiting:
            return "Waiting to start…"
        case .active:
            return nil
        case .complete(let details):
            if let details {
                return details.size.formatted(.byteCount(style: .file))
            } else {
                return "Complete"
            }
        case .cancelled:
            return "Cancelled"
        case .failed(let error):
            return error.localizedDescription
        }

    }

    var body: some View {
        HStack(spacing: LayoutMetrics.horizontalSpacing) {

            self.image
            
            VStack(alignment: .leading, spacing: 0) {

                Text(name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .horizontalSpace(.trailing)

                switch transfer.status {
                case .waiting:
                    ProgressView(value: 0)
                        .controlSize(.small)
                case .active(let progress):
                    ProgressView(progress)
                        .controlSize(.small)
                case .complete, .cancelled, .failed:
                    EmptyView()
                }

                if let statusText {
                    Text(statusText)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .help(statusText)
                }

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
            case .complete(let details):
                if let details {
                    Button {
                        switch details.reference {
                        case .local(let url):
                            Application.reveal(url)
                        case .remote:
                            print("Revealing remote files is not currently supported!")
                        }
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
