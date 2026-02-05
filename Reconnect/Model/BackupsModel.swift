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

@Observable
class BackupsModel {

    private let rootURL: URL
    private let workQueue = DispatchQueue(label: "BackupsModel.workQueue")

    var devices: [DeviceConfiguration] = []

    @ObservationIgnored
    weak public var delegate: BackupsModelDelegate?

    init(rootURL: URL) {
        self.rootURL = rootURL
    }

    func update() {
        workQueue.async {
            do {
                let fileManager = FileManager.default

                // Load the backups.
                let fileURLs = try fileManager.contentsOfDirectory(at: self.rootURL,
                                                                   includingPropertiesForKeys: [.isDirectoryKey])

                let devices = fileURLs.compactMap { fileURL -> DeviceConfiguration? in
                    let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    guard isDirectory else {
                        return nil
                    }
                    let configURL = fileURL.appendingPathComponent("config.ini")
                    guard fileManager.fileExists(at: configURL) else {
                        return nil
                    }
                    return try? DeviceConfiguration(data: try Data(contentsOf: configURL))
                }
                DispatchQueue.main.async {
                    self.devices = devices
                    self.delegate?.backupsModel(self, didUpdateDevices: devices)
                }
            } catch {
                print("Failed to enumerate directories with error \(error).")
            }
        }
    }

}
