// Reconnect -- Psion connectivity for macOS
//
// Copyright (C) 2024 Jason Morley
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

import Foundation

import ArgumentParser

import ReconnectCore
import OpoLua

enum Path {
    case file(String)
    case directory(String)
}

class Installer {

    let fileServer: FileServer
    let interpreter = PsiLuaEnv()

    var paths: [Path] = []

    init(fileServer: FileServer) {
        self.fileServer = fileServer
    }

    func install(_ url: URL) async throws {
        try interpreter.installSisFile(path: url.path, handler: self)
    }

}

extension Installer: SisInstallIoHandler {

    func fsop(_ op: Fs.Operation) -> Fs.Result {
        switch op.type {
        case .write(let data):
            let directory = NSTemporaryDirectory()
            let fileName = NSUUID().uuidString
            let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])!
            do {
                let destinationDirectory = op.path.deletingLastWindowsPathComponent
                try data.write(to: fullURL)
                if !(try fileServer.fileExistsSync(path: destinationDirectory)) {
                    print("Creating directory '\(destinationDirectory)'...")
                    try fileServer.mkdirSync(path: destinationDirectory)
                    paths.append(.directory(destinationDirectory))
                }
                print("Writing file '\(op.path)'...")
                try fileServer.copyFileSync(fromLocalPath: fullURL.path, toRemotePath: op.path)
            } catch {
                print("Failed to write file '\(op.path)' with error '\(error)'.")
                return .err(.notReady)
            }
            paths.append(.file(op.path))
            return .err(.none)
        default:
            print("unsupported operation '\(op)'")
            return .err(.notReady)
        }
    }

}

@main
struct Command: AsyncParsableCommand {

    public static var configuration = CommandConfiguration(version: version())

    static func version() -> String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        else {
            return "unknown"
        }
        let components: [String] = [version, buildNumber]
        return components.joined(separator: " ")
    }

    @Argument(help: "The SIS file to install.")
    var installer: String

    @Argument(help: "Path to screenshot utility (screenshot.exe).")
    var screenshot: String

    @Argument(help: "Screenshot output directory path.")
    var outputDirectory: String

    func sleep(seconds: Double) async throws {
        print("Sleeping for \(seconds) seconds...")
        try await Task.sleep(for: .seconds(seconds))
    }

    mutating func run() async throws {

        print("Installing '\(installer)'...")
        let fileServer = FileServer()
        let client = RemoteCommandServicesClient()
        let url = URL(filePath: installer)
        let installer = Installer(fileServer: fileServer)

        // Install the SIS file.
        try await installer.install(url)

        // Install the screenshot file.
        try await fileServer.copyFile(fromLocalPath: screenshot, toRemotePath: "C:\\screenshot.exe")

        // Detect the apps.
        let applications = installer.paths.compactMap { (path) -> String? in
            switch path {
            case .file(let path):
                guard path.lowercased().hasSuffix(".app") else {
                    return nil
                }
                return path
            case .directory(_):
                return nil
            }
        }

        if let application = applications.first {

            // Launch the app.
            print("Running app...")
            try client.execProgram(program: "Z:\\System\\Apps\\OPL\\OPL.app", args: "A" + application)

            // Wait for the app to start.
            try await sleep(seconds: 30)

            // Take a screenshot.
            print("Taking screenshot...")
            try client.execProgram(program: "C:\\screenshot.exe", args: "")

            // Wait for the screenshot.
            try await sleep(seconds: 5)

            // Copy the screenshot.
            let outputURL = URL(filePath: outputDirectory).appendingPathComponent("screenshot.mbm")
            try await fileServer.copyFile(fromRemotePath: "C:\\screenshot.mbm", toLocalPath: outputURL.path)
            try await fileServer.remove(path: "C:\\screenshot.mbm")
            try PsiLuaEnv().convertMultiBitmap(at: outputURL, removeSource: true)

        }

        // Close all the running programs.
        print("Stopping all programs...")
        try client.stopPrograms()

        try await sleep(seconds: 10)

        // Delete the files.
        print("Cleaning up files...")
        try await fileServer.remove(path: "C:\\screenshot.exe")
        for path in installer.paths.reversed() {
            switch path {
            case .file(let path):
                try await fileServer.remove(path: path)
            case .directory(let path):
                try await fileServer.rmdir(path: path)
            }
        }

        print("Done.")
    }

}
