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

import Socket
import DataStream

extension Socket {

    func write(_ value: [UInt8]) throws {
        try write(from: Data(value))
    }

    func write(_ string: String) throws {
        try write(from: string.data(using: .ascii)!)
    }

    // Seems to use null-terminated strings.
    func send(_ string: String) throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, UInt8(string.count + 1)])
        data.append(string.data(using: .ascii)!)
        data.append(contentsOf: [0x00])
        try write(from: data)
    }

    func response() throws -> Data {
        var response = Data()
        try read(into: &response)
        let stream = DataReadStream(data: response)
        let length: UInt32 = try stream.read()
        let message: Data = try stream.read(count: Int(length))
        return message
    }

    func process() throws {
        let data = try response()
        let response = String(data: data, encoding: .ascii)!
        print(response)
    }

    func response<T: Packable>() throws -> T {
        let data = try response()
        return try T(from: DataReadStream(data: data))
    }

    func sendReceive(_ data: Data) throws -> DataReadStream {
        return try sendReceive([UInt8](data))
    }


    func sendReceive(_ data: [UInt8]) throws -> DataReadStream {
        try write([0x00, 0x00, 0x00, UInt8(data.count)] + data)
        var response = Data()
        try read(into: &response)
        let stream = DataReadStream(data: response)
        let length: UInt32 = try stream.read()
        let message: Data = try stream.read(count: Int(length))
        return DataReadStream(data: message)
    }

}
