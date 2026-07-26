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

import Foundation

/**
 * The context in which a file transfer (upload or download) occurs.
 *
 * This maps closely to the purpose of the transfer and how it was initiated. It is used to determine what transform
 * operation to perform when transfering the file.
 */
enum FileTransferContext {

    /**
     * Transfer is the result of a drag-and-drop operation.
     */
    case drag

    /**
     * Transfer is the result of a user interaction (e.g., clicking the download toolbar button or menu item).
     */
    case interactive

    /**
     * Transfer is part of a backup operation.
     */
    case backup

    /**
     * Transfer is a simple copy with no file conversion.
     */
    case copy

}
