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

import ReconnectCore

enum BrowserSection: Hashable {
    case connecting
    case drive(FileServer.DriveInfo)  // TODO: Differentiate between these?
    case directory(FileServer.DriveInfo, String)
    case device
    case softwareIndex
}

extension BrowserSection {

    var title: String {
        switch self {
        case .connecting:
            return "Connecting..."
        case .drive(let driveInfo):
            return driveInfo.displayName
        case .directory(_, let path):
            // TODO: Make this right.
            return path
        case .device:
            return "My Psion"
        case .softwareIndex:
            return "Software Index"
        }
    }

    var image: String {
        switch self {
        case .connecting:
            return "Disconnected16"
        case .drive(let driveInfo):
            return driveInfo.image
        case .directory:
            return "Folder16"
        case .device:
            return "Psion16"
        case .softwareIndex:
            return "Install16"
        }
    }

}
