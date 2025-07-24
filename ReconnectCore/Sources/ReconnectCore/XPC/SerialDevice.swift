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

public class SerialDevice: NSObject, NSSecureCoding, Identifiable {

    enum CodingKeys: String {
        case path
        case isAvailable
        case isEnabled
    }

    public static var supportsSecureCoding = true

    public var id: String {
        return path
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(path)
        hasher.combine(isAvailable)
        hasher.combine(isEnabled)
        return hasher.finalize()
    }

    public override var debugDescription: String {
        return "{path: '\(path)', isAvailable: \(isAvailable), isEnabled: \(isEnabled)}"
    }

    public let path: String
    public let isAvailable: Bool
    public let isEnabled: Bool

    public func encode(with coder: NSCoder) {
        coder.encode(path, forKey: CodingKeys.path.rawValue)
        coder.encode(isAvailable, forKey: CodingKeys.isAvailable.rawValue)
        coder.encode(isEnabled, forKey: CodingKeys.isEnabled.rawValue)
    }
    
    public required init?(coder: NSCoder) {
        guard let path = coder.decodeObject(of: NSString.self, forKey: CodingKeys.path.rawValue) as String?
        else {
            return nil
        }
        self.path = path
        self.isAvailable = coder.decodeBool(forKey: CodingKeys.isAvailable.rawValue)
        self.isEnabled = coder.decodeBool(forKey: CodingKeys.isEnabled.rawValue)
    }

    public init(path: String, isAvailable: Bool, isEnabled: Bool) {
        self.path = path
        self.isAvailable = isAvailable
        self.isEnabled = isEnabled
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SerialDevice else {
            return false
        }
        return (object.path == path &&
                object.isAvailable == isAvailable &&
                object.isEnabled == isEnabled)
    }

}
