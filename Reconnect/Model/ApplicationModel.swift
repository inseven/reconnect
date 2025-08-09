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

    let menuApplicationLoginService = SMAppService.loginItem(identifier: .menuApplicationBundleIdentifier)

    public var openAtLogin: Bool {
        get {
            access(keyPath: \.openAtLogin)
            return menuApplicationLoginService.status == .enabled
        }
        set {
            withMutation(keyPath: \.openAtLogin) {
                print("Login item status = \(menuApplicationLoginService.status == .enabled)")
                do {
                    if newValue {
                        if menuApplicationLoginService.status == .enabled {
                            try? menuApplicationLoginService.unregister()
                        }
                        print("Registering login item...")
                        try menuApplicationLoginService.register()
                    } else {
                        print("Unregistering login item...")
                        try menuApplicationLoginService.unregister()
                    }
                } catch {
                    print("Failed to update service with error \(error).")
                }
            }
        }
    }

    var hasUsableSerialDevices: Bool {
        return !serialDevices
            .filter { $0.isUsable }
            .isEmpty
    }

    nonisolated let logger = Logger()
    nonisolated let daemonClient = DaemonClient()

    var updaterController: SPUStandardUpdaterController!

    // General applicaiton state.
    var launching: Bool = true
    var activeSettingsSection: SettingsView.SettingsSection = .general
    var isDaemonConnected = false
    var serialDevices = [SerialDevice]()
    var devices: [DeviceModel] = []

    let transfersModel = TransfersModel()

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

        // Clear the launching flag after an acceptable timeout.
        // This is used in the UI to select between whether we should show a spinner while waiting to connect to the
        // daemon or a connection failure. This is intended as a short term work around in lieu of an improved view
        // and view model hierarchy around managing multiple connected devices.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            self.launching = false
        }
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
        terminateAnyIncompatibleMenuBarApplications()
        let embeddedAppURL = Bundle.main.bundleURL.appendingPathComponents(["Contents", "Library", "LoginItems", "Reconnect Menu.app"])
        let openConfiguration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: embeddedAppURL, configuration: openConfiguration)
    }

    nonisolated func terminateRunningMenuApplications() {
        NSRunningApplication.terminateRunningApplications(bundleIdentifier: .menuApplicationBundleIdentifier,
                                                          waitForCompletion: true)
    }

    private func terminateAnyIncompatibleMenuBarApplications() {
        let embeddedAppURL = Bundle.main.bundleURL.appendingPathComponents(["Contents", "Library", "LoginItems", "Reconnect Menu.app"])
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
        // Disconnect from the daemon and shut down the menu bar app prior to relanuching the app.
        daemonClient.disconnect()
        terminateRunningMenuApplications()
    }

}

extension ApplicationModel: DaemonClientDelegate {

    func daemonClientDidConnect(_ daemonClient: DaemonClient) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.isDaemonConnected = true
    }

    func daemonClientDidDisconnect(_ daemonClient: DaemonClient) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.isDaemonConnected = false
        self.devices = []
    }

    func daemonClient(_ daemonClient: DaemonClient, didUpdateDeviceConnectionState isDeviceConnected: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        if isDeviceConnected {
            // Create a new `DeviceModel` that encapsulates all PLP sessions with the newly attached Psion.
            // We pre-warm the model before adding it into the UI to ensure that the UI can immediately select a
            // suitable drive to display.
            // TODO: This is currently racy.
            let deviceModel = DeviceModel(applicationModel: self)
            deviceModel.start { error in
                // TODO: Do something with the error??
                DispatchQueue.main.async {
                    self.devices = [deviceModel]
                }
            }
        } else {
            self.devices = []
        }
    }

    func daemonClient(_ daemonClient: ReconnectCore.DaemonClient, didUpdateSerialDevices serialDevices: [SerialDevice]) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.serialDevices = serialDevices
    }

}

extension ApplicationModel: LibraryModelDelegate {

    func libraryModelDidCancel(libraryModel: LibraryModel) {

    }

    func libraryModel(libraryModel: LibraryModel, didSelectItem item: PsionSoftwareIndexView.Item) {
        do {
            let url = try FileManager.default.safelyMoveItem(at: item.url, toDirectory: .downloadsDirectory)
            showInstallerWindow(url: url)
        } catch {
            // TODO: Handle these errors!
            print("Failed to handle download with error \(error).")
        }
    }

}
