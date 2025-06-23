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

public class PsionClient {

    let fileServer = FileServer()
    let remoteCommandServices = RemoteCommandServicesClient()

    public init() {
        
    }

    public func runProgram(path: String) async throws {
        let attributes = try await fileServer.getExtendedAttributes(path: path)
        if attributes.uid1 == .dynamicLibraryUid {
            try remoteCommandServices.execProgram(program: path)
        } else {
            try remoteCommandServices.execProgram(program: "Z:\\System\\Apps\\OPL\\OPL.app", args: "A" + path)
        }
    }

    public func runProgram(path: String) throws {
        let attributes = try fileServer.getExtendedAttributesSync(path: path)
        if attributes.uid1 == .dynamicLibraryUid {
            try remoteCommandServices.execProgram(program: path)
        } else {
            try remoteCommandServices.execProgram(program: "Z:\\System\\Apps\\OPL\\OPL.app", args: "A" + path)
        }
    }

}
