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

struct DisconnectedView: View {

    @Environment(ApplicationModel.self) private var applicationModel

    var body: some View {
        if !applicationModel.isDaemonConnected {
            if applicationModel.launching {
                ProgressView()
            } else {
                ContentUnavailableView {
                    Label("Daemon Not Running", systemImage: "exclamationmark.octagon")
                } description: {
                    Text("Reconnect is unable to connect to reconnectd. This manages the serial connection and allows both the main Reconnect and menu bar apps to talk to your Psion. Restarting your computer might help.")
                }
            }
        } else if !applicationModel.hasUsableSerialDevices {
            ContentUnavailableView {
                Label("Not Connected", systemImage: "cable.connector.slash")
            } description: {
                Text("No serial devices available. Make sure you have connected and enabled a serial adapter.")
            } actions: {
                SettingsButton("Open Connection Settings...", section: .devices)
            }
        } else if applicationModel.isConnecting {
            ContentUnavailableView {
                Label {
                    Text("Connecting...")
                } icon: {
                    ProgressAnimation("cnt")
                }
            } actions: {
                SettingsButton()
            }
        } else {
            ContentUnavailableView {
                Label("Not Connected", systemImage: "cable.connector")
            } actions: {
                SettingsButton()
            }
        }

    }

}
