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
        case convertFiles
        case downloadsURL
        case screenshotsURL
        case selectedDevices
        case revealScreenshots
    }

    var convertFiles: Bool {
        didSet {
            keyedDefaults.set(convertFiles, forKey: .convertFiles)
        }
    }

    var downloadsURL: URL {
        didSet {
            do {
                try keyedDefaults.set(securityScopedURL: downloadsURL, forKey: .downloadsURL)
            } catch {
                print("Failed to save downloads path with error \(error).")
            }
        }
    }

    var revealScreenshots: Bool {
        didSet {
            keyedDefaults.set(revealScreenshots, forKey: .revealScreenshots)
        }
    }

    var screenshotsURL: URL {
        didSet {
            do {
                try keyedDefaults.set(securityScopedURL: screenshotsURL, forKey: .screenshotsURL)
            } catch {
                print("Failed to save screenshots path with error \(error).")
            }
        }
    }

    let updaterController = SPUStandardUpdaterController(startingUpdater: false,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)

    private let keyedDefaults = KeyedDefaults<SettingsKey>()

    override init() {
        convertFiles = keyedDefaults.bool(forKey: .convertFiles, default: true)
        downloadsURL = (try? keyedDefaults.securityScopedURL(forKey: .downloadsURL)) ?? .downloadsDirectory
        revealScreenshots = keyedDefaults.bool(forKey: .revealScreenshots, default: true)
        screenshotsURL = (try? keyedDefaults.securityScopedURL(forKey: .screenshotsURL)) ?? .downloadsDirectory
        super.init()
        openMenuApplication()
        updaterController.startUpdater()
    }

    func installGuestTools() {
        showInstallerWindow(url: Bundle.main.url(forResource: "ReconnectTools", withExtension: "sis")!)
    }

    func openInstaller() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.sis]
        guard openPanel.runModal() ==  NSApplication.ModalResponse.OK else {
            return
        }
        for url in openPanel.urls {
            showInstallerWindow(url: url)
        }
    }

    func openMenuApplication() {
        guard let embeddedAppURL = Bundle.main.url(forResource: "Reconnect Menu", withExtension: "app") else {
            return
        }
        let openConfiguraiton = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: embeddedAppURL, configuration: openConfiguraiton)
    }

    func showInstallerWindow(url: URL) {

        // Ignore urls used for launching Reconnect from the menu bar.
        guard url.isFileURL else {
            return
        }

        // Check to see if there's already an open window for the installer.
        var window = NSApplication.shared.windows.first { window in
            guard let window = window as? NSInstallerWindow else {
                return false
            }
            return window.url == url
        }

        // Create a new window and center if one doesn't exist.
        if window == nil {
            print("Creating new installer window for '\(url)'...")
            window = NSInstallerWindow(url: url)
            window?.center()
        }

        // Foreground the window.
        window?.makeKeyAndOrderFront(nil)
    }

}
