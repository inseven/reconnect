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

import ReconnectCore

@MainActor @Observable
class TransfersModel {

    var transfers: [Transfer] = []
    var selection: UUID? = nil

    init() {
    }

    func newTransfer(fileReference: FileReference) -> Transfer {
        TransfersWindow.reveal()
        let transfer = Transfer(item: fileReference)
        DispatchQueue.main.async {
            self.transfers.append(transfer)
        }
        return transfer
    }

    func clear() {
        transfers.removeAll { !$0.isActive }
    }

}
