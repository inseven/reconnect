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

import Foundation

import ncp

public class RemoteCommandServicesClient {

    public typealias MachineType = rpcs.machs
    public typealias MachineInfo = rpcs.machineInfo

    private let host: String
    private let port: Int32

    private let workQueue = DispatchQueue(label: "RemoteCommandServicesClient.workQueue")

    private var client = RPCSClient()

    public init(host: String = "127.0.0.1", port: Int32 = 7501) {
        self.host = host
        self.port = port
    }

    private func workQueue_connect<T>(perform: (inout RPCSClient) throws -> T) throws -> T {
        guard self.client.connect(self.host, self.port) else {
            throw ReconnectError.unknown
        }
        return try perform(&client)
    }

    private func withClient<T>(perform: (inout RPCSClient) throws -> T) throws -> T {
        dispatchPrecondition(condition: .notOnQueue(workQueue))
        return try workQueue.sync {
            return try self.workQueue_connect(perform: perform)
        }
    }

    public func getMachineType() throws -> MachineType {
        return try withClient { client in
            var machs: MachineType = .PSI_MACH_UNKNOWN
            try client.getMachineType(&machs).check()
            return machs
        }
    }

    public func getMachineInfo() throws -> MachineInfo {
        return try withClient { client in
            var machineInfo = rpcs.machineInfo()
            try client.getMachineInfo(&machineInfo).check()
            return machineInfo
        }
    }

    // TODO: Inject the code page?
    public func getOwnerInfo() throws -> [String] {
        return try withClient { client in
            var buf: bufferArray = bufferArray()
            try client.getOwnerInfo(&buf).check()
            var ownerInfo = [String]()
            while !buf.empty() {
                let data = Data(store: buf.pop())
                let line = data.withUnsafeBytes { bytes in
                    return String(cString: bytes.bindMemory(to: CChar.self).baseAddress!, encoding: .windowsCP1252)!
                }
                ownerInfo.append(line)
            }
            return ownerInfo
        }
    }

    public func execProgram(program: String, args: String = "") throws {
        return try withClient { client in
            try client.execProgram(program, args).check()
        }
    }

    public func stopPrograms() throws {
        return try withClient { client in
            try client.stopPrograms().check()
        }
    }

}


extension Data {

    init(store: bufferStore) {
        var bytes: [UInt8] = []
        for i in 0..<store.getLen() {
            bytes.append(store.getByte(Int(i)))
        }
        self.init(bytes)
    }

}
