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

import Diligence

extension URL {

    public static let about = URL(string: "x-reconnect://about")!
    public static let browser = URL(string: "x-reconnect://browser")!
    public static let transfers = URL(string: "x-reconnect://transfers")!
    public static let programManager = URL(string: "x-reconnect://program-manager")!
    public static let psionSoftwareIndex = URL(string: "x-reconnect://psion-software-index")!
    public static let update = URL(string: "x-reconnect://update")!

    public static let discord = URL(string: "https://discord.gg/ZUQDhkZjkK")!
    public static let donate = URL(string: "https://jbmorley.co.uk/support")!
    public static let gitHub = URL(string: "https://github.com/inseven/reconnect")!
    public static let software = URL(string: "https://jbmorley.co.uk/software")!

    public static var support: URL = {
        let subject = "Reconnect Support (\(Bundle.main.extendedVersion ?? "Unknown Version"))"
        return URL(address: "support@jbmorley.co.uk", subject: subject)!
    }()

    public func appendingPathComponents(_ pathComponents: [String]) -> URL {
        return pathComponents.reduce(self) { url, pathComponent in
            return url.appendingPathComponent(pathComponent)
        }
    }

    public func deletingLastPathComponents(_ count: Int) -> URL {
        return URL(fileURLWithPath: NSString.path(withComponents: pathComponents.dropLast(count)))
    }

}
