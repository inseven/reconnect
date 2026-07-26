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

public class DaemonInfo: NSObject, NSSecureCoding {

    enum CodingKeys: String {
        case version
        case buildNumber
    }

    public static var supportsSecureCoding = true

    public override var description: String {
        debugDescription
    }

    public override var debugDescription: String {
        return "{version = \(version ?? "?"), buildNumber = \(buildNumber ?? "?")'}"
    }

    public let version: String?
    public let buildNumber: String?

    public init(version: String?, buildNumber: String?) {
        self.version = version
        self.buildNumber = buildNumber
    }

    public required init?(coder: NSCoder) {
        self.version = coder.decodeObject(of: NSString.self, forKey: CodingKeys.version.rawValue) as? String
        self.buildNumber = coder.decodeObject(of: NSString.self, forKey: CodingKeys.buildNumber.rawValue) as? String
    }

    public func encode(with coder: NSCoder) {
        coder.encode(version, forKey: CodingKeys.version.rawValue)
        coder.encode(buildNumber, forKey: CodingKeys.buildNumber.rawValue)
    }

}
