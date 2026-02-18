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

public struct DeviceCommands: Commands {

    @Environment(ApplicationModel.self) private var applicationModel: ApplicationModel

    @FocusedObject private var deviceProxy: DeviceModelProxy?

    var canCaptureScreenshot: Bool {
        guard let deviceModel = deviceProxy?.deviceModel, !deviceModel.isCapturingScreenshot else {
            return false
        }
        return true
    }

    public var body: some Commands {

        CommandMenu("Device") {

            Button("Back Up...", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                deviceProxy?.deviceModel.backUp()
            }
            .keyboardShortcut("B", modifiers: [.command])

            Button("Capture Screenshot", systemImage: "camera.viewfinder") {
                deviceProxy?.deviceModel.captureScreenshot()
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
            .disabled(!canCaptureScreenshot)

            Divider()

            Button("Install Reconnect Tools...", systemImage: "shippingbox") {
                deviceProxy?.deviceModel.installGuestTools()
            }
            .disabled(deviceProxy == nil)

        }

    }

}
