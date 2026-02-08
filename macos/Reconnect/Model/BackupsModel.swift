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

extension FileManager {

    func directories(at url: URL) throws -> [URL] {
        return try contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { url in
                return (try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
    }

}

// Guaranteed to be called on the main queue.
protocol BackupsModelDelegate: NSObjectProtocol {

    func backupsModel(_ backupsModel: BackupsModel, didUpdateBackupSets backupSets: [BackupSet])

}

extension String {
    static let manifestFilename = "manifest.json"
}

@Observable
class BackupsModel {

    private let rootURL: URL
    private let workQueue = DispatchQueue(label: "BackupsModel.workQueue")

    var backupSets: [BackupSet] = []

    @ObservationIgnored
    weak public var delegate: BackupsModelDelegate?

    init(rootURL: URL) {
        self.rootURL = rootURL
    }

    static func loadSets(rootURL: URL) throws -> [Backup] {
        let fileManager = FileManager.default
        let backups = try fileManager
            .directories(at: rootURL)
            .compactMap { directoryURL -> Backup? in
                let manifestURL = directoryURL.appendingPathComponent(.manifestFilename)
                guard fileManager.fileExists(at: manifestURL) else {
                    return nil
                }
                let manifest = try BackupManifest(contentsOf: manifestURL)
                return Backup(manifest: manifest, url: directoryURL)
            }
        return backups
    }

    func update() {
        workQueue.async {
            do {
                let fileManager = FileManager.default

                // Load the backups.
                let backupSets = try fileManager
                    .directories(at: self.rootURL)
                    .compactMap { directoryURL -> BackupSet? in
                        let configURL = directoryURL.appendingPathComponent("config.ini")
                        guard fileManager.fileExists(at: configURL) else {
                            return nil
                        }
                        let deviceConfiguration = try DeviceConfiguration(data: try Data(contentsOf: configURL))
                        let backups = try Self.loadSets(rootURL: directoryURL)
                        guard !backups.isEmpty else {
                            return nil
                        }
                        return BackupSet(device: deviceConfiguration, backups: backups)
                    }

                // Update the model state.
                DispatchQueue.main.async {
                    self.backupSets = backupSets
                    self.delegate?.backupsModel(self, didUpdateBackupSets: backupSets)
                }

            } catch {
                print("Failed to enumerate directories with error \(error).")
            }
        }
    }

}
