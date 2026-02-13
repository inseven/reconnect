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

import os
import ServiceManagement
import SwiftUI

import Interact
import Sparkle
import Security

import ReconnectCore

// Guaranteed to be called on the main queue.
protocol ApplicationModelConnectionDelegate: NSObjectProtocol {

    func applicationModel(_ applicationModel: ApplicationModel, deviceDidConnect deviceModel: DeviceModel)
    func applicationModel(_ applicationModel: ApplicationModel, deviceDidDisconnect deviceModel: DeviceModel)

}

@MainActor @Observable
class ApplicationModel: NSObject {

    enum SettingsKey: String {
        case convertDraggedFiles
        case convertFiles
        case downloadsURL
        case screenshotsURL
        case revealScreenshots
    }

    var error: Error? = nil

    var convertDraggedFiles: Bool {
        didSet {
            keyedDefaults.set(convertDraggedFiles, forKey: .convertDraggedFiles)
        }
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

    var backupsURL: URL

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

    @ObservationIgnored
    weak public var connectionDelegate: ApplicationModelConnectionDelegate?

    // General applicaiton state.
    var launching: Bool = true
    var activeSettingsSection: SettingsView.SettingsSection = .general
    var isDaemonConnected = false
    var serialDevices = [SerialDevice]()
    var longRunningOperations: Set<UUID> = []

    // Queue of devices that are being loaded; we keep them in a separate queue to ensure we don't present them in the
    // UI until they're ready to be fully displayed.
    private var connectingDevices: [UUID: CancellationToken] = [:]

    // TODO: This should be a set.
    var devices: [DeviceModel] = []

    /**
     * Indciates whether there's a device currently connecting.
     *
     * This is inferred by the length of the `connectingDevices` array which tracks devices currently being initialized.
     */
    var isConnecting: Bool {
        return !connectingDevices.isEmpty
    }

    let transfersModel = TransfersModel()
    let libraryModel = LibraryModel()
    let navigationModel = NavigationModel<BrowserSection>(element: .disconnected)
    let backupsModel: BackupsModel

    private let keyedDefaults = KeyedDefaults<SettingsKey>()

    override init() {
        convertDraggedFiles = keyedDefaults.bool(forKey: .convertDraggedFiles, default: true)
        convertFiles = keyedDefaults.bool(forKey: .convertFiles, default: true)
        downloadsURL = (try? keyedDefaults.securityScopedURL(forKey: .downloadsURL)) ?? .downloadsDirectory
        revealScreenshots = keyedDefaults.bool(forKey: .revealScreenshots, default: true)
        screenshotsURL = (try? keyedDefaults.securityScopedURL(forKey: .screenshotsURL)) ?? .downloadsDirectory

#if DEBUG
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Reconnect-Debug")
#else
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Reconnect")
#endif

        let backupsURL = applicationSupportURL.appending(path: "Backups", directoryHint: .isDirectory)
        self.backupsURL = backupsURL
        backupsModel = BackupsModel(rootURL: backupsURL)
        super.init()
        updaterController = SPUStandardUpdaterController(startingUpdater: false,
                                                         updaterDelegate: self,
                                                         userDriverDelegate: nil)
        navigationModel.delegate = self
        daemonClient.delegate = self
        daemonClient.connect()
        openMenuApplication()
        updaterController.startUpdater()
        libraryModel.delegate = self
        backupsModel.update()

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
            window = NSInstallerWindow(applicationModel: self, url: url)
            window?.center()
        }

        // Foreground the window.
        window?.makeKeyAndOrderFront(nil)
    }

    func showBackupWindow(deviceModel: DeviceModel) {

        // Check to see if there's already an open window for the installer.
        var window = NSApplication.shared.windows.first { window in
            guard let window = window as? NSBackupWindow else {
                return false
            }
            return window.deviceModelId == deviceModel.id
        }


        // Create a new window and center if one doesn't exist.
        if window == nil {
            window = NSBackupWindow(applicationModel: self, deviceModel: deviceModel)
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

    func daemonClient(_ daemonClient: ReconnectCore.DaemonClient,
                      didUpdateSerialDevices serialDevices: [SerialDevice]) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.serialDevices = serialDevices
    }

    func daemonClient(_ daemonClient: DaemonClient, deviceDidConnect connectionDetails: DeviceConnectionDetails) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Create a new `DeviceModel` that encapsulates all PLP sessions with the newly attached Psion.
        // We inject a cancellation token to allow us to cancel the initialization mid-flow if we need to.
        let cancellationToken = CancellationToken()
        DeviceModel.initialize(applicationModel: self,
                               connectionDetails: connectionDetails,
                               cancellationToken: cancellationToken) { result in
            DispatchQueue.main.async { [self] in

                // Remove our cancellation token.
                _ = connectingDevices.removeValue(forKey: connectionDetails.id)

                // Check the cancellation token to ensure we weren't cancelled while being dispatched.
                guard !cancellationToken.isCancelled else {
                    return
                }
                switch result {
                case .success(let deviceModel):

                    // Set the delegate.
                    deviceModel.delegate = self

                    // Update the back up identifier for this device, and re-enumerate the backups.
                    let deviceBackupsURL = backupsURL
                        .appending(path: deviceModel.id.uuidString, directoryHint: .isDirectory)
                    let configURL = deviceBackupsURL.appending(path: "config.ini")
                    if !FileManager.default.fileExists(at: deviceBackupsURL) {
                        try? FileManager.default.createDirectory(at: deviceBackupsURL, withIntermediateDirectories: true)
                    }
                    try? deviceModel.deviceConfiguration.data().write(to: configURL, options: .atomic)
                    backupsModel.update()

//                    devices = [deviceModel]
                    devices.append(deviceModel)
                    connectionDelegate?.applicationModel(self, deviceDidConnect: deviceModel)
                    print("Device \(deviceModel.id.uuidString) connected.")
                case .failure(let error):
                    print("Failed to initialize device with error \(error).")
                    self.error = error
                }
            }
        }
        self.connectingDevices[connectionDetails.id] = cancellationToken
    }

    func daemonClient(_ daemonClient: DaemonClient, deviceDidDisconnect connectionDetails: DeviceConnectionDetails) {
        dispatchPrecondition(condition: .onQueue(.main))
        if let deviceModel = devices.first(where: { $0.connectionDetails.id == connectionDetails.id }) {
            connectionDelegate?.applicationModel(self, deviceDidDisconnect: deviceModel)
            devices.removeAll { $0.id == deviceModel.id }
        }
        if let cancellationToken = connectingDevices.removeValue(forKey: connectionDetails.id) {
            cancellationToken.cancel()
        }
    }

}

// TODO: @MainActor here doesn't appear to do anything other than silence the compiler?
extension ApplicationModel: @MainActor DeviceModelDelegate {

    func deviceModel(deviceModel: DeviceModel, willStartBackupWithIdentifier identifier: UUID) {
        self.longRunningOperations.insert(identifier)
    }

    func deviceModel(deviceModel: DeviceModel, didFinishBackupWithIdentifier identifier: UUID, backup: Backup) {
        self.backupsModel.update()
        self.longRunningOperations.remove(identifier)
    }

    func deviceModel(deviceModel: DeviceModel, didFailBackupWithIdentifier identifier: UUID, error: any Error) {
        self.longRunningOperations.remove(identifier)
    }

}

extension ApplicationModel: LibraryModelDelegate {

    func libraryModelDidCancel(libraryModel: LibraryModel) {

    }

    func libraryModel(libraryModel: LibraryModel, didSelectItem item: LibraryModel.Item) {
        do {
            let url = try FileManager.default.safelyMoveItem(at: item.url, toDirectory: .downloadsDirectory)
            showInstallerWindow(url: url)
        } catch {
            // TODO: Handle these errors!
            print("Failed to handle download with error \(error).")
        }
    }

}

extension ApplicationModel: @MainActor NavigationModelDelegate {

    func navigationModel(_ navigationModel: NavigationModel<BrowserSection>,
                                     canNavigateToItem item: BrowserSection) -> Bool {
        switch item {
        case .disconnected:
            return self.devices.isEmpty
        case .drive(let deviceId, _, _), .directory(let deviceId, _, _), .device(let deviceId, _):
            return self.devices.first?.id == deviceId
        case .softwareIndex, .program(_):
            return true
        case .backupSet(_):
            return true
        case .backup(_):
            return true
        }
    }

}
