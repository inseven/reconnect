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

import ncp
import plpftp

public class RemoteCommandServicesClient {

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

    public func execProgram(program: String, args: String) throws {
        return try withClient { client in
            client.execProgram(program, args)
        }
    }

    public func queryPrograms() throws {
        return try withClient { client in
            var ret = processList()
            client.queryPrograms(&ret)
            print("Start")
            for var i in ret {
                print(i.getPID())
                withUnsafeMutablePointer(to: &i) { pointer in
                    print(String(cString: psiprocess_get_name(pointer)))
                }
            }
        }
    }

}
