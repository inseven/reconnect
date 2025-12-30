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

import OpoLuaCore

import ReconnectCore

extension RemoteCommandServicesClient.MachineType {

    var isEpoc32: Bool {
        switch self {
        case .unknown, .pc, .mc, .hc, .series3, .series3acmx, .workabout, .siena, .series3c:
            return false
        case .series5, .winC:
            return true
        }
    }
}

@Observable
class DeviceModel: Identifiable, Equatable {

    static func == (lhs: DeviceModel, rhs: DeviceModel) -> Bool {
        return lhs.id != rhs.id
    }

    @MainActor var machineType: RemoteCommandServicesClient.MachineType = .unknown
    @MainActor var machineInfo: RemoteCommandServicesClient.MachineInfo? = nil
    @MainActor var drives: [FileServer.DriveInfo] = []
    @MainActor var isCapturingScreenshot: Bool = false

    @MainActor
    var internalDrive: FileServer.DriveInfo? {
        dispatchPrecondition(condition: .onQueue(.main))
        return drives.first { driveInfo in
            return driveInfo.mediaType == .ram
        }
    }

    @MainActor
    var installDirectory: String? {
        switch machineType {
        case .unknown, .pc, .mc, .hc, .winC:
            return nil
        case .series3, .series3acmx, .workabout, .siena, .series3c:
            return .epoc16InstallDirectory
        case .series5:
            return .epoc32InstallDirectory
        }
    }

    @MainActor
    var canCaptureScreenshot: Bool {
        switch machineType {
        case .unknown, .pc, .mc, .hc, .winC:
            return false
        case .series3, .series3acmx, .workabout, .siena, .series3c:
            return false
        case .series5:
            return true
        }
    }

    let id = UUID()

    let fileServer = FileServer()
    let remoteCommandServicesClient = RemoteCommandServicesClient()

    @ObservationIgnored
    private weak var applicationModel: ApplicationModel?

    private let workQueue = DispatchQueue(label: "DeviceModel.workQueue")

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
    }

    func start(completion: @escaping (Error?) -> Void) {
        workQueue.async { [self] in
            do {

                // Bootstrap the connection to the Psion, inferring the type of the deivce we're connected to and its
                // limitations as we go. There are probably better appraoches to this, but this at least gets things
                // working, and we can revisit them in the future.

                // 1) Perform a drive listing. We know we can always safely do this.
                let drives = try fileServer.drivesSync()

                // 2) Once we have a drive list, we can infer that we're talking to an EPOC16 device by the presence of
                //    a RAM-drive labeled M.
                let epoc16 = drives.first(where: { driveInfo in
                    return driveInfo.mediaType == .ram && driveInfo.drive == "M"
                }) != nil

                // 3) If we're EPOC16, we need to ensure the RPCS server is installed on the Psion, copying it if not.
                if try (epoc16 && !fileServer.exists(path: "M:\\SYS$RPCS.IMG")) {
                    let rpcsServer = Bundle.main.url(forResource: "SYS$RPCS", withExtension: ".IMG")!
                    try fileServer.copyFileSync(fromLocalPath: rpcsServer.path, toRemotePath: "M:\\SYS$RPCS.IMG") { _, _ in return .continue }
                }

                // 4) Once we've made sure the RPCS server is present irrespective of the machine we're using, we can
                //    fetch the machine type.
                let machineType = try remoteCommandServicesClient.getMachineType()

                // 5) We then use the machine type as a more fine-grained way to determine if it's safe to fetch the
                //    full machine info.
                let machineInfo: RemoteCommandServicesClient.MachineInfo? = if machineType.isEpoc32 {
                    try remoteCommandServicesClient.getMachineInfo()
                } else {
                    nil
                }

                // 6) And with all that done, it's safe to hand back to the UI with enough information to allow things
                //    to continue and conditionally display things correctly. 😬
                DispatchQueue.main.sync {
                    self.machineType = machineType
                    self.machineInfo = machineInfo
                    self.drives = drives
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func runInBackground(perform: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try perform()
            } catch {
                // TODO: Surface these errors to the user.
                print("Failed to perform background operation with error \(error).")
            }
        }
    }

    @MainActor
    func captureScreenshot() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let applicationModel else {
            return
        }

        let screenshotsURL = applicationModel.screenshotsURL
        let revealScreenshot = applicationModel.revealScreenshots
        isCapturingScreenshot = true

        let transfersModel = applicationModel.transfersModel

        runInBackground { [transfersModel] in

            defer {
                DispatchQueue.main.async {
                    self.isCapturingScreenshot = false
                }
            }

            let nameFormatter = DateFormatter()
            nameFormatter.dateFormat = "'Reconnect Screenshot' yyyy-MM-dd 'at' HH.mm.ss"

            let fileManager = FileManager.default
            let fileServer = FileServer()
            let client = RemoteCommandServicesClient()

            // Check to see if the guest tools are installed.
            guard try fileServer.exists(path: .reconnectToolsStubPath) else {
                throw ReconnectError.missingTools
            }

            // Create a temporary directory.
            let temporaryDirectory = try fileManager.createTemporaryDirectory()
            defer {
                try? fileManager.removeItemLoggingErrors(at: temporaryDirectory)
            }

            // Take a screenshot.
            print("Taking screenshot...")
            let timestamp = Date.now
            try client.execProgram(program: .screenshotToolPath, args: "")
            sleep(5)

            // Rename the screenshot before transferring it to allow us to defer renaming to the transfers model.
            let name = nameFormatter.string(from: timestamp)
            let screenshotPath = "C:\\\(name).mbm"
            try fileServer.rename(from: .screenshotPath, to: screenshotPath)

            // Perhaps the transfer model can use some paired down reference which includes the type?
            let screenshotDetails = try fileServer.getExtendedAttributesSync(path: screenshotPath)

            TransfersWindow.reveal()

            Task {

                // Download and convert the screenshot.
                let outputURL = try await transfersModel.download(from: screenshotDetails,
                                                                  to: screenshotsURL) { entry, url in
                    let destinationURL = url.deletingLastPathComponent()
                    let outputURL = destinationURL.appendingPathComponent(url.lastPathComponent.deletingPathExtension,
                                                                          conformingTo: .png)
                    try PsiLuaEnv().convertMultiBitmap(at: url, to: outputURL, type: .png)
                    try FileManager.default.removeItem(at: url)
                    return outputURL
                }

                // Cleanup.
                try fileServer.remove(path: screenshotPath)

                // Reveal the screenshot.
                await MainActor.run {
                    if revealScreenshot {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }

            }

        }
    }

}
