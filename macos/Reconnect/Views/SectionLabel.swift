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

struct SectionLabel: View {

    let applicationModel: ApplicationModel
    let section: BrowserSection

    init(applicationModel: ApplicationModel, section: BrowserSection) {
        self.applicationModel = applicationModel
        self.section = section
    }

    var body: some View {
        Label {
            Group {
                switch section {
                case .disconnected:
                    Text("Not Connected")
                case .drive(_, let driveInfo, _):
                    Text(driveInfo.displayName)
                case .directory(_, _, let path):
                    Text(path.lastWindowsPathComponent)
                case .device(let deviceId):
                    if let deviceModel = applicationModel.deviceModel(for: deviceId) {
                        Text(deviceModel.name)
                    } else {
                        Text("Unknown")
                    }
                case .softwareIndex:
                    Text("Software Index")
                case .program(let program):
                    Text(program.name)
                case .backupSet(let device):
                    Text(device.name)
                case .backup(let backup):
                    Text(backup.manifest.date, format: .dateTime)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            switch section {
            case .disconnected:
                Image(.disconnected16)
            case .drive(_, let driveInfo, let platform):
                Image(DisplayHelpers.imageForDrive(driveInfo.drive,
                                                   mediaType: driveInfo.mediaType,
                                                   platform: platform))
            case .directory:
                Image(.folder16)
            case .device:
                Image(.psion16)
            case .softwareIndex:
                Image(.install16)
            case .program(let program):
                if let iconURL = program.iconURL {
                    FixedSizeAsyncImage(url: iconURL, size: CGSize(width: 16, height: 16)) {
                        Image(.fileUnknown16)
                    }
                } else {
                    Image(.fileUnknown16)
                }
            case .backupSet(_):
                Image(.backup16)
            case .backup(_):
                Image(.backup16)
            }
        }
    }

}
