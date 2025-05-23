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
import Sparkle

@MainActor @Observable
class ApplicationModel: NSObject {

    struct SerialDevice: Identifiable {

        var id: String {
            return path
        }

        var path: String
        var available: Bool
        var enabled: Binding<Bool>
    }

    enum SettingsKey: String {
        case selectedDevices
        case convertFiles
    }

    var convertFiles: Bool {
        didSet {
            keyedDefaults.set(convertFiles, forKey: .convertFiles)
        }
    }

    let updaterController = SPUStandardUpdaterController(startingUpdater: false,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)

    private let keyedDefaults = KeyedDefaults<SettingsKey>()

    override init() {
        convertFiles = keyedDefaults.bool(forKey: .convertFiles, default: true)
        super.init()
        openMenuApplication()
        updaterController.startUpdater()
    }

    func openMenuApplication() {
        guard let embeddedAppURL = Bundle.main.url(forResource: "Reconnect Menu", withExtension: "app") else {
            return
        }
        let openConfiguraiton = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: embeddedAppURL, configuration: openConfiguraiton)
    }

}
