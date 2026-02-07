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

enum BrowserSection: Hashable {
    case disconnected
    case drive(UUID, FileServer.DriveInfo, Platform)
    case directory(UUID, FileServer.DriveInfo, String)
    case device(UUID, String)
    case softwareIndex
    case program(SoftwareIndex.Program)
    case backupSet(DeviceConfiguration)
    case backup(Backup)
}

extension BrowserSection {

    var title: String {
        switch self {
        case .disconnected:
            return "Not Connected"
        case .drive(_, let driveInfo, _):
            return driveInfo.displayName
        case .directory(_, _, let path):
            return path.lastWindowsPathComponent
        case .device(_, let name):
            return name
        case .softwareIndex:
            return "Software Index"
        case .program(let program):
            return program.name
        case .backupSet(let device):
            return device.name
        case .backup(let backup):
            return backup.manifest.date.formatted()
        }
    }

    var image: String {
        switch self {
        case .disconnected:
            return "Disconnected16"
        case .drive(_, let driveInfo, let platform):
            switch platform {
            case .epoc16:
                if driveInfo.drive == "A" || driveInfo.drive == "B" {
                    return "SSD16"
                } else {
                    return "Drive16"
                }
            case .epoc32:
                switch driveInfo.mediaType {
                case .disk:
                    return "Disk16"
                default:
                    return "Drive16"
                }
            }
        case .directory:
            return "Folder16"
        case .device:
            return "Psion16"
        case .softwareIndex:
            return "Install16"
        case .program:
            return "FileUnknown16"
        case .backupSet(_):
            return "Backup16"
        case .backup(_):
            return "Backups16"
        }
    }

}
