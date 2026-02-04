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

import Interact
import OpoLuaCore

import ReconnectCore

@Observable
class InstallerModel: Runnable {

    struct ConfigurationQuery: Identifiable {

        let id = UUID()
        let installDirectory: String
        let defaultDrive: String
        let sis: Sis.File
        let defaultLanguage: String
        let drives: [FileServer.DriveInfo]

        private let completion: (Sis.BeginResult) -> Void

        init(installDirectory: String,
             defaultDrive: String,
             sis: Sis.File,
             drives: [FileServer.DriveInfo],
             defaultLanguage: String,
             completion: @escaping (Sis.BeginResult) -> Void) {
            self.installDirectory = installDirectory
            self.defaultDrive = defaultDrive
            self.sis = sis
            self.drives = drives
            self.defaultLanguage = defaultLanguage
            self.completion = completion
        }

        func `continue`(drive: String, language: String) {
            completion(.install(.init(drive: drive,
                                      stubDir: installDirectory,
                                      language: language)))
        }

        func cancel() {
            completion(.userCancelled)
        }

    }

    struct ReplaceQuery: Identifiable {

        let id = UUID()

        let sis: Sis.File
        let replacing: Sis.Installation

        private let completion: (Bool) -> Void

        init(sis: Sis.File,
             replacing: Sis.Installation,
             completion: @escaping (Bool) -> Void) {
            self.sis = sis
            self.replacing = replacing
            self.completion = completion
        }

        func resume(_ result: Bool) {
            completion(result)
        }

    }

    struct TextQuery: Identifiable {

        let id = UUID()
        let sis: Sis.File
        let text: String
        let type: Sis.QueryType
        private let completion: (Bool) -> Void

        init(sis: Sis.File, text: String, type: Sis.QueryType, completion: @escaping (Bool) -> Void) {
            self.sis = sis
            self.text = text
            self.type = type
            self.completion = completion
        }

        func resume(_ continue: Bool) {
            completion(`continue`)
        }

    }

    enum Page {
        case loading
        case ready
        case checkingInstalledPackages(Double)
        case operation(Fs.Operation, Progress)
        case error(Error)
        case complete
    }

    enum Query: Identifiable {

        var id: UUID {
            switch self {
            case .configuration(let configurationQuery):
                return configurationQuery.id
            case .replace(let replaceQuery):
                return replaceQuery.id
            case .text(let textQuery):
                return textQuery.id
            }
        }

        case configuration(ConfigurationQuery)
        case replace(ReplaceQuery)
        case text(TextQuery)
    }

    private let applicationModel: ApplicationModel
    private var device: DeviceModel?
    private let url: URL

    var sis: Sis.File?
    var page: Page = .loading
    var query: Query?

    init(applicationModel: ApplicationModel, url: URL) {
        self.applicationModel = applicationModel
        self.url = url
    }

    func start() {
        device = applicationModel.devices.first
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                // Determine which device we're using.
                guard self.device != nil else {
                    throw PLPToolsError.unitDisconnected
                }

                // Load the installer details.
                let sis = try PsiLuaEnv().loadSisFile(url: self.url)

                // Indicate that we're ready and kick off the install process.
                DispatchQueue.main.sync {
                    self.sis = sis
                    self.page = .ready
                    self.install()
                }
            } catch {
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }

    func stop() {

    }

    func install() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let interpreter = PsiLuaEnv()
                try interpreter.installSisFile(path: self.url.path, handler: self)
                DispatchQueue.main.async {
                    self.page = .complete
                }
            } catch {
                print("Failed to install SIS file with error \(error).")
                DispatchQueue.main.async {
                    self.page = .error(error)
                }
            }
        }
    }

    private func getConfiguration(sis: Sis.File, driveRequired: Bool) -> Sis.BeginResult {
        dispatchPrecondition(condition: .notOnQueue(.main))

        // We pull this functionality out into a separate function because the Swift compiler (poor thing) fails to
        // realize the only error this can throw is a `PLPToolsError` if we use it directly in the `do` block.
        func showConfigurationQuery(sis: Sis.File, driveRequired: Bool) throws(PLPToolsError) -> Sis.BeginResult {
            dispatchPrecondition(condition: .notOnQueue(.main))
            guard let device else {
                throw .unitDisconnected
            }
            guard let installDirectory = device.installDirectory else {
                throw .notSupported
            }
            let drives = try device.fileServer.drivesSync().filter { driveInfo in
                driveInfo.mediaType != .rom
            }
            let sem = DispatchSemaphore(value: 0)
            let defaultLanguage = try! Locale.selectLanguage(sis.languages)
            var result: Sis.BeginResult = .userCancelled
            DispatchQueue.main.sync {
                let query = ConfigurationQuery(installDirectory: installDirectory,
                                               defaultDrive: device.internalDrive.drive,
                                               sis: sis,
                                               drives: drives,
                                               defaultLanguage: defaultLanguage) { selection in
                    result = selection
                    sem.signal()
                }
                self.query = .configuration(query)
            }
            sem.wait()
            defer {
                DispatchQueue.main.sync {
                    self.query = nil
                }
            }
            return result
        }
        do {
            return try showConfigurationQuery(sis: sis, driveRequired: driveRequired)
        } catch {
            return .epocError(error.rawValue)
        }
    }

    private func getShouldInstallOrReplace(sis: Sis.File, replacing: Sis.Installation?, isRoot: Bool) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))

        // If there's nothing to relpace, we always install.
        guard let replacing else {
            return true
        }

        // If the installer is nested, we perform some automatic versioining to match the Psion implementation.
        if !isRoot {

            // If new version is the same as the old version, skip the install.
            if sis.version == replacing.version {
                return false
            }

            // If the new version is greater than the old version, install.
            if sis.version > replacing.version {
                return true
            }

        }

        // If we're unsure, ask the user.
        let sem = DispatchSemaphore(value: 0)
        var result: Bool = false
        DispatchQueue.main.sync {
            let query = ReplaceQuery(sis: sis, replacing: replacing) { selection in
                result = selection
                sem.signal()
            }
            self.query = .replace(query)
        }
        defer {
            DispatchQueue.main.sync {
                self.query = nil
            }
        }
        sem.wait()
        return result
    }

}

extension InstallerModel: SisInstallIoHandler {

    func sisGetStubs() -> Sis.GetStubsResult {
        dispatchPrecondition(condition: .notOnQueue(.main))

        do {
            guard let device else {
                throw PLPToolsError.unitDisconnected
            }
            let installDirectory = DispatchQueue.main.sync {
                return device.installDirectory
            }
            guard let installDirectory else {
                throw PLPToolsError.notSupported
            }

            // Ensure the install directory exists on the Psion.
            if !(try device.fileServer.exists(path: installDirectory)) {
                try device.fileServer.mkdir(path: installDirectory)
            }

            // Index the existing stubs.
            let stubs = try device.fileServer.getStubs(installDirectory: installDirectory) { progress in
                DispatchQueue.main.sync {
                    self.page = .checkingInstalledPackages(progress.fractionCompleted)
                }
                return .continue
            }
            return .stubs(stubs)
        } catch {
            if let error = error as? PLPToolsError {
                return .epocError(error.rawValue)
            } else {
                print("Encountered unmapped internal plptools error during install '\(error)'.")
                return .epocError(PLPToolsError.unknown.rawValue)
            }
        }
    }

    func sisInstallBegin(sis: Sis.File, context: Sis.BeginContext) -> Sis.BeginResult {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Installing '\(sis.name)'...")

        // Prompt the user for the initial installation details.
        let result = getConfiguration(sis: sis, driveRequired: context.driveRequired)
        guard case Sis.BeginResult.install = result else {
            return result
        }

        // Work out if we should replace the existing install, prompting the user if necessary.
        if !getShouldInstallOrReplace(sis: sis, replacing: context.replacing, isRoot: context.isRoot) {
            if context.isRoot {
                return .userCancelled
            } else {
                return .skipInstall
            }
        }

        return result
    }

    func sisInstallQuery(sis: Sis.File, text: String, type: Sis.QueryType) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let sem = DispatchSemaphore(value: 0)
        var result: Bool = false
        DispatchQueue.main.sync {
            let query = TextQuery(sis: sis, text: text, type: type) { response in
                result = response
                sem.signal()
            }
            self.query = .text(query)
        }
        defer {
            DispatchQueue.main.sync {
                self.query = nil
            }
        }
        sem.wait()
        return result
    }

    func sisInstallRun(sis: Sis.File, path: String, flags: Sis.RunFlags) {
        dispatchPrecondition(condition: .notOnQueue(.main))
        do {
            let services = PsionClient()
            try services.runProgram(path: path)
        } catch {
            print("Failed to run path '\(path)' with error '\(error)'.")
        }
    }

    func sisInstallRollback(sis: Sis.File) -> Bool {
        print("Rolling back...")
        return true
    }

    func sisInstallComplete(sis: Sis.File) {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Install phase complete (\(sis.name)).")
    }

    func fsop(_ operation: Fs.Operation) -> Fs.Result {
        dispatchPrecondition(condition: .notOnQueue(.main))
        print("Perform operation \(operation)...")
        guard let device else {
            return .epocError(PLPToolsError.unitDisconnected.rawValue)
        }
        return device.fileServer.fsop(operation) { progress in
            DispatchQueue.main.sync {
                self.page = .operation(operation, progress)
            }
        }
    }

}
