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

import Foundation

import ncp
import plpftp

public class FileServer {

    public enum MediaType: UInt32 {
        case notPresent = 0
        case unknown = 1
        case floppy = 2
        case disk = 3
        case compactDisc = 4
        case ram = 5
        case flashDisk = 6
        case rom = 7
        case remote = 8
    }

    public enum ProgressResponse: Int32 {
        case cancel = 0
        case `continue` = 1
    }

    public struct FileAttributes: OptionSet {

        public static let readOnly = FileAttributes(rawValue: 0x0001)
        public static let hidden = FileAttributes(rawValue: 0x0002)
        public static let system = FileAttributes(rawValue: 0x0004)
        public static let directory = FileAttributes(rawValue: 0x0008)
        public static let archive = FileAttributes(rawValue: 0x0010)
        public static let volume = FileAttributes(rawValue: 0x0020)

        // EPOC
        public static let normal = FileAttributes(rawValue: 0x0040)
        public static let temporary = FileAttributes(rawValue: 0x0080)
        public static let compressed = FileAttributes(rawValue: 0x0100)

        // SIBO
        public static let read = FileAttributes(rawValue: 0x0200)
        public static let exec = FileAttributes(rawValue: 0x0400)
        public static let stream = FileAttributes(rawValue: 0x0800)
        public static let text = FileAttributes(rawValue: 0x1000)

        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

    }

    public struct DriveInfo: Identifiable {

        public var id: String {
            return drive
        }

        public let drive: String
        public let mediaType: MediaType
        public let name: String?
    }

    public struct DirectoryEntry: Identifiable, Hashable {

        public var id: String {
            return path
        }

        public var isDirectory: Bool {
            return attributes.contains(.directory)
        }

        public var path: String
        public var name: String
        public var size: UInt32
        public var attributes: FileAttributes
        public var modificationDate: Date

        public var uid1: UInt32
        public var uid2: UInt32
        public var uid3: UInt32

        public init(path: String,
             name: String,
             size: UInt32,
             attributes: FileAttributes,
             modificationDate: Date,
             uid1: UInt32,
             uid2: UInt32,
             uid3: UInt32) {
            self.path = path
            self.name = name
            self.size = size
            self.attributes = attributes
            self.modificationDate = modificationDate
            self.uid1 = uid1
            self.uid2 = uid2
            self.uid3 = uid3
        }

        init(directoryPath: String, entry: PlpDirent) {
            var entry = entry
            let name = String(cString: plpdirent_get_name(&entry))
            let attributes = FileAttributes(rawValue: entry.getAttr())
            let filePath = directoryPath
                .appendingWindowsPathComponent(name, isDirectory: attributes.contains(.directory))
            var modificationTime = entry.getPsiTime()
            let modificationTimeInterval = TimeInterval(modificationTime.getTime())
            let modificationDate = Date(timeIntervalSince1970: modificationTimeInterval)

            self.path = filePath
            self.name = name
            self.size = entry.getSize()
            self.attributes = attributes
            self.modificationDate = modificationDate
            self.uid1 = entry.getUID(0)
            self.uid2 = entry.getUID(1)
            self.uid3 = entry.getUID(2)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(path)
        }

    }

    private class FileTransferContext {

        let callback: (UInt32, UInt32) -> ProgressResponse
        let size: UInt32

        init(size: UInt32, callback: @escaping (UInt32, UInt32) -> ProgressResponse) {
            self.size = size
            self.callback = callback
        }

    }

    static var drives: [String] = {
        return Array(65..<91).map { String(UnicodeScalar($0)) }
    }()

    private let host: String
    private let port: Int32

    private let workQueue = DispatchQueue(label: "FileServer.workQueue")

    private var client = RFSVClient()

    public init(host: String = "127.0.0.1", port: Int32 = 7501) {
        self.host = host
        self.port = port
    }

    private func perform<T>(action: @escaping () throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            workQueue.async {
                do {
                    let result = try action()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func syncQueue_connect() throws {
        guard self.client.connect(self.host, self.port) else {
            throw ReconnectError.unknown
        }
    }

    private func syncQueue_dir(path: String, recursive: Bool) throws -> [DirectoryEntry] {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        var details = PlpDir()
        try client.dir(path, &details).check()

        var entries: [DirectoryEntry] = []
        for i in 0..<details.count {
            entries.append(DirectoryEntry(directoryPath: path, entry: details[i]))
        }
        guard recursive else {
            return entries
        }

        var result: [DirectoryEntry] = []
        for entry in entries {
            result.append(entry)
            if entry.isDirectory {
                result.append(contentsOf: try syncQueue_dir(path: entry.path, recursive: true))
            }
        }
        return result
    }

    func syncQueue_getExtendedAttributes(path: String) throws -> DirectoryEntry {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        var entry = PlpDirent()
        try client.fgeteattr(path, &entry).check()
        return DirectoryEntry(directoryPath: path.deletingLastWindowsPathComponent, entry: entry)
    }

    func syncQueue_copyFile(fromRemotePath remoteSourcePath: String,
                            toLocalPath localDestinationPath: String,
                            callback: @escaping (UInt32, UInt32) -> ProgressResponse) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()

        let attributes = try syncQueue_getExtendedAttributes(path: remoteSourcePath)
        let o = FileTransferContext(size: attributes.size, callback: callback)
        let context = Unmanaged.passUnretained(o).toOpaque()
        let result = client.copyFromPsion(remoteSourcePath, localDestinationPath, context) { context, status in
            guard let context else {
                return 0
            }
            let o = Unmanaged<FileTransferContext>.fromOpaque(context).takeUnretainedValue()
            return o.callback(status, o.size).rawValue
        }
        try result.check()
    }

    func syncQueue_copyFile(fromLocalPath localSourcePath: String,
                            toRemotePath remoteDestinationPath: String,
                            callback: @escaping (UInt32, UInt32) -> ProgressResponse) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        let attributes = try FileManager.default.attributesOfItem(atPath: localSourcePath)
        guard let size = attributes[.size] as? NSNumber else {
            throw ReconnectError.unknownFileSize
        }
        let o = FileTransferContext(size: UInt32(size.intValue), callback: callback)
        let context = Unmanaged.passUnretained(o).toOpaque()
        let result = client.copyToPsion(localSourcePath, remoteDestinationPath, context) { context, status in
            guard let context else {
                return 0
            }
            let o = Unmanaged<FileTransferContext>.fromOpaque(context).takeUnretainedValue()
            return o.callback(status, o.size).rawValue
        }
        try result.check()
    }

    func syncQueue_mkdir(path: String) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        try client.mkdir(path).check()
    }

    func syncQueue_rmdir(path: String) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        try client.rmdir(path).check()
    }

    func syncQueue_remove(path: String) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        try client.remove(path).check()
    }

    func syncQueue_rename(from fromPath: String, to toPath: String) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        try client.rename(fromPath, toPath).check()
    }

    func syncQueue_devlist() throws -> [String] {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        var devbits: UInt32 = 0
        try client.devlist(&devbits).check()
        return Self.drives
            .enumerated()
            .compactMap { index, drive -> String? in
                guard (devbits & (0x01 << index)) > 0 else {
                    return nil
                }
                return drive
            }
    }

    func syncQueue_devinfo(drive: String) throws -> DriveInfo {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try syncQueue_connect()
        let d = drive.cString(using: .ascii)!.first!
        var driveInfo = PlpDrive()
        try client.devinfo(d, &driveInfo).check()
        guard let mediaType = MediaType(rawValue: driveInfo.getMediaType()) else {
            throw ReconnectError.unknownMediaType
        }
        let name = string_cstr(driveInfo.getName())!

        return DriveInfo(drive: drive,
                         mediaType: mediaType,
                         name: String(cString: name))
    }

    public func dir(path: String, recursive: Bool = false) async throws -> [DirectoryEntry] {
        return try await perform {
            return try self.syncQueue_dir(path: path, recursive: recursive)
        }
    }

    // TODO: Consider dropping the default callback?
    public func copyFile(fromRemotePath remoteSourcePath: String,
                         toLocalPath localDestinationPath: String,
                         callback: @escaping (UInt32, UInt32) -> ProgressResponse = { _, _ in return .continue }) async throws {
        try await perform {
            try self.syncQueue_copyFile(fromRemotePath: remoteSourcePath,
                                        toLocalPath: localDestinationPath,
                                        callback: callback)
        }
    }

    public func copyFile(fromLocalPath localSourcePath: String,
                         toRemotePath remoteDestinationPath: String,
                         callback: @escaping (UInt32, UInt32) -> ProgressResponse = { _, _ in return .continue }) async throws {
        try await perform {
            try self.syncQueue_copyFile(fromLocalPath: localSourcePath,
                                        toRemotePath: remoteDestinationPath,
                                        callback: callback)
        }
    }

    public func copyFileSync(fromLocalPath localSourcePath: String,
                             toRemotePath remoteDestinationPath: String,
                             callback: @escaping (UInt32, UInt32) -> ProgressResponse = { _, _ in return .continue }) throws {
        dispatchPrecondition(condition: .notOnQueue(workQueue))
        try workQueue.sync {
            try self.syncQueue_copyFile(fromLocalPath: localSourcePath,
                                        toRemotePath: remoteDestinationPath,
                                        callback: callback)
        }
    }


    // TODO: Separate the sync and async implementations into different layers?
    public func getExtendedAttributes(path: String) async throws -> DirectoryEntry {
        try await perform {
            return try self.syncQueue_getExtendedAttributes(path: path)
        }
    }

    public func getExtendedAttributesSync(path: String) throws -> DirectoryEntry {
        return try workQueue.sync {
            return try self.syncQueue_getExtendedAttributes(path: path)
        }
    }

    public func fileExistsSync(path: String) throws -> Bool {
        dispatchPrecondition(condition: .notOnQueue(workQueue))
        return workQueue.sync {
            do {
                let _ = try self.syncQueue_getExtendedAttributes(path: path)
                return true
            } catch {
                return false
            }
        }
    }

    public func mkdir(path: String) async throws {
        try await perform {
            try self.syncQueue_mkdir(path: path)
        }
    }

    public func mkdirSync(path: String) throws {
        dispatchPrecondition(condition: .notOnQueue(workQueue))
        try workQueue.sync {
            try self.syncQueue_mkdir(path: path)
        }
    }

    public func rmdir(path: String) async throws {
        try await perform {
            try self.syncQueue_rmdir(path: path)
        }
    }

    public func remove(path: String) async throws {
        try await perform {
            try self.syncQueue_remove(path: path)
        }
    }

    public func rename(from fromPath: String, to toPath: String) async throws {
        try await perform {
            try self.syncQueue_rename(from: fromPath, to: toPath)
        }
    }

    public func drives() async throws -> [DriveInfo] {
        try await perform {
            var result: [DriveInfo] = []
            for drive in try self.syncQueue_devlist() {
                do {
                    result.append(try self.syncQueue_devinfo(drive: drive))
                } catch FileServerError.driveNotReady {
                    continue
                }
            }
            return result
        }
    }

}
