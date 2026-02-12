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

public class DeviceConnectionDetails: NSObject, NSSecureCoding, Identifiable {

    enum CodingKeys: String {
        case id
        case port
    }

    public static let supportsSecureCoding = true

    public let id: UUID
    public let port: Int32

    public override var debugDescription: String {
        return "{id = \(id.uuidString), port = \(port)}"
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }

    public init(port: Int32) {
        self.id = UUID()
        self.port = port
    }

    public required init?(coder: NSCoder) {
        guard
            let idString = coder.decodeObject(of: NSString.self, forKey: CodingKeys.id.rawValue) as? String,
            let id = UUID(uuidString: idString)
        else {
            return nil
        }
        self.id = id
        self.port = coder.decodeInt32(forKey: CodingKeys.port.rawValue)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(id.uuidString, forKey: CodingKeys.id.rawValue)
        coder.encode(port, forKey: CodingKeys.port.rawValue)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? DeviceConnectionDetails else {
            return false
        }
        return (object.id == id &&
                object.port == port)
    }

}
