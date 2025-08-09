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

import OpoLua

import ReconnectCore

@Observable
class DeviceModel: Identifiable, Equatable {

    static func == (lhs: DeviceModel, rhs: DeviceModel) -> Bool {
        return lhs.id != rhs.id
    }

    let id = UUID()

    var machineInfo = RemoteCommandServicesClient.MachineInfo()
    var ownerInfo: String = ""
    var drives: [FileServer.DriveInfo] = []
    var isCapturingScreenshot: Bool = false

    var internalDrive: FileServer.DriveInfo? {
        return drives.first { driveInfo in
            return driveInfo.mediaType == .ram
        }
    }

    // TODO: WHERE DO I SHOW ERRORS FROM HERE?

    let fileServer = FileServer()
    let remoteCommandServicesClient = RemoteCommandServicesClient()

    @ObservationIgnored
    private weak var applicationModel: ApplicationModel?  // TODO: Might be cleaner to inject a separate settings model?

    private let workQueue = DispatchQueue(label: "DeviceModel.workQueue")

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
    }

    // TODO: Cancellable??
    func start(completion: @escaping (Error?) -> Void) {
        workQueue.async { [self] in
            do {
                let machineInfo = try remoteCommandServicesClient.getMachineInfo()
                let ownerInfo = try remoteCommandServicesClient.getOwnerInfo()
                let drives = try fileServer.drivesSync()
                DispatchQueue.main.sync {
                    self.machineInfo = machineInfo
                    self.ownerInfo = ownerInfo.joined(separator: "\n")
                    self.drives = drives
                }
                completion(nil)
            } catch {
                // TODO: Work out where to save this!
                //            lastError = error
                completion(error)
            }
        }
    }

    // TODO: This is a hack.
    private func run(task: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try task()
            } catch {
                DispatchQueue.main.sync {
                    // TODO: Store the error somewhere!
//                    self.lastError = error
                }
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

        run { [transfersModel] in

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
            try fileServer.rename(from: .screenshotPath, to: screenshotPath)  // TODO: Sync version of this?

            // TODO: This feels like overkill as a way to synthesize a directory entry.
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
