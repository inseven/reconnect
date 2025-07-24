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

import os
import ServiceManagement
import SwiftUI

import Interact
import Sparkle
import Security

import ReconnectCore

@MainActor @Observable
class ApplicationModel: NSObject {

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
                logger.error("Failed to save downloads path with error '\(error)'")
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
                logger.error("Failed to save screenshots path with error '\(error)'")
            }
        }
    }

    var serialDevices: [SerialDevice] = []

    var updaterController: SPUStandardUpdaterController!

    let daemonClient = DaemonClient()
    let logger = Logger()

    private let keyedDefaults = KeyedDefaults<SettingsKey>()

    override init() {
        convertFiles = keyedDefaults.bool(forKey: .convertFiles, default: true)
        downloadsURL = (try? keyedDefaults.securityScopedURL(forKey: .downloadsURL)) ?? .downloadsDirectory
        revealScreenshots = keyedDefaults.bool(forKey: .revealScreenshots, default: true)
        screenshotsURL = (try? keyedDefaults.securityScopedURL(forKey: .screenshotsURL)) ?? .downloadsDirectory
        super.init()
        updaterController = SPUStandardUpdaterController(startingUpdater: false,
                                                         updaterDelegate: self,
                                                         userDriverDelegate: nil)
        daemonClient.delegate = self
        daemonClient.connect()
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
        openPanel.allowedContentTypes = [.sis, .sisOpoLua]
        guard openPanel.runModal() ==  NSApplication.ModalResponse.OK else {
            return
        }
        for url in openPanel.urls {
            showInstallerWindow(url: url)
        }
    }

    private func openMenuApplication() {
//#if !DEBUG
        terminateAnyIncompatibleMenuBarApplications()
//#else
//        // In debug, we always restart the menu bar applicaiton to ease development.
//        terminateRunningMenuApplications()
//#endif
        let embeddedAppURL = Bundle.main.url(forResource: "Reconnect Menu", withExtension: "app")!
        let openConfiguration = NSWorkspace.OpenConfiguration()
        openConfiguration.allowsRunningApplicationSubstitution = false
        NSWorkspace.shared.openApplication(at: embeddedAppURL, configuration: openConfiguration)
    }

    nonisolated private func terminateRunningMenuApplications() {
        NSRunningApplication.terminateRunningApplications(withBundleIdentifier: .menuApplicationBundleIdentifier)
    }

    private func terminateAnyIncompatibleMenuBarApplications() {
        let embeddedAppURL = Bundle.main.url(forResource: "Reconnect Menu", withExtension: "app")!
        let expectedHash = getCDHashForBinary(at: embeddedAppURL)
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: .menuApplicationBundleIdentifier)
        for app in runningApps {
            let hash = getCDHashForPID(app.processIdentifier)
            guard hash != expectedHash else {
                continue
            }
            app.terminate()
            while !app.isTerminated {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }
    }

    private func getCDHashForBinary(at url: URL) -> Data? {
        var staticCode: SecStaticCode?
        var signingInfo: CFDictionary?
        guard
            SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode) == errSecSuccess,
            let staticCode,
            SecCodeCopySigningInformation(staticCode, [], &signingInfo) == errSecSuccess,
            let signingInfo = signingInfo as? [String: Any],
            let hashes = signingInfo["cdhashes"] as? [Data]
        else {
            return nil
        }
        return hashes.first
    }

    private func getCDHashForPID(_ pid: pid_t) -> Data? {
        let attributes = [kSecGuestAttributePid: pid] as CFDictionary
        var code: SecCode?
        var staticCode: SecStaticCode?
        var signingInfo: CFDictionary?
        guard
            SecCodeCopyGuestWithAttributes(nil, attributes, [], &code) == errSecSuccess,
            let code,
            SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode) == errSecSuccess,
            let staticCode,
            SecCodeCopySigningInformation(staticCode,
                                          SecCSFlags(rawValue: kSecCSDynamicInformation),
                                          &signingInfo) == errSecSuccess,
            let signingInfo = signingInfo as? [String: Any],
            let hashes = signingInfo["cdhashes"] as? [Data]
        else {
            return nil
        }
        return hashes.first
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
            logger.debug("Creating new installer window for '\(url)'...")
            window = NSInstallerWindow(url: url)
            window?.center()
        }

        // Foreground the window.
        window?.makeKeyAndOrderFront(nil)
    }

}

extension ApplicationModel: SPUUpdaterDelegate {

    nonisolated func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        // Shut down the menu bar app prior to relanuching the app.
        terminateRunningMenuApplications()
    }

}

extension ApplicationModel: DaemonClientDelegate {

    func daemonClient(_ daemonClient: ReconnectCore.DaemonClient,
                      didUpdateSerialDevices devices: [SerialDevice]) {
        dispatchPrecondition(condition: .onQueue(.main))
        print("daemon(didUpdateSerialDevices:)")
        self.serialDevices = serialDevices
    }

}
