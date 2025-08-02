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

public class SerialDeviceConfiguration: NSObject, NSSecureCoding, Codable {

    public static let availableBaudRates: [Int32] = [
        0,
        300,
        600,
        1200,
        2400,
        4800,
        9600,
        19200,
        38400,
        57600,
        115200,
    ]

    enum CodingKeys: String, CodingKey {
        case baudRate
    }

    public static let supportsSecureCoding: Bool = true

    public override var debugDescription: String {
        return "{baudRate = \(baudRate)}"
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(baudRate)
        return hasher.finalize()
    }

    public let baudRate: Int32

    public init(baudRate: Int32 = 0) {
        self.baudRate = baudRate
    }

    public required init?(coder: NSCoder) {
        self.baudRate = coder.decodeInt32(forKey: CodingKeys.baudRate.rawValue)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(baudRate, forKey: CodingKeys.baudRate.rawValue)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SerialDeviceConfiguration else {
            return false
        }
        return (object.baudRate == baudRate)
    }

}
