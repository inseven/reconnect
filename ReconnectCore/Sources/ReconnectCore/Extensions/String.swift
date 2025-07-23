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

public extension String {

    static let installDirectory = "C:\\System\\Install\\"
    static let reconnectToolsStubPath = "C:\\System\\Install\\ReconnectTools.sis"
    static let screenshotPath = "C:\\screenshot.mbm"
    static let screenshotToolPath = "C:\\System\\Reconnect\\screenshot.exe"
    static let windowsPathSeparator = "\\"

    static let browserApplicationBundleIdentifier = "uk.co.jbmorley.reconnect.apps.apple"
    static let menuApplicationBundleIdentifier = "uk.co.jbmorley.reconnect.apps.apple.menu"

    static let daemonSericeName = "uk.co.jbmorley.reconnect.apps.apple.xpc.daemon"

    var deletingLastWindowsPathComponent: String {
        return windowsPathComponents
            .dropLast()
            .joined(separator: .windowsPathSeparator)
    }

    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }

    var isRoot: Bool {
        return windowsPathComponents.count == 1
    }

    var isWindowsDirectory: Bool {
        return hasSuffix(.windowsPathSeparator)
    }

    var lastWindowsPathComponent: String {
        return windowsPathComponents.last ?? ""
    }

    var pathExtension: String {
        return (self as NSString).pathExtension
    }

    var windowsPathComponents: [String] {
        return components(separatedBy: "\\").filter { !$0.isEmpty }
    }

    init(contentsOfResource resource: String) {
        let url = Bundle.main.url(forResource: resource, withExtension: nil)!
        try! self.init(contentsOf: url)
    }

    func appendingPathExtension(_ pathExtension: String) -> String {
        return "\(self).\(pathExtension)"
    }

    func appendingWindowsPathComponent(_ component: String, isDirectory: Bool = false) -> String {
        return windowsPathComponents
            .appending(component)
            .joined(separator: .windowsPathSeparator)
            .ensuringTrailingWindowsPathSeparator(isPresent: isDirectory)
    }

    func ensuringTrailingWindowsPathSeparator(isPresent: Bool = true) -> String {
        switch (isWindowsDirectory, isPresent) {
        case (true, false):
            return windowsPathComponents
                .joined(separator: .windowsPathSeparator)
        case (false, true):
            return self.appending(String.windowsPathSeparator)
        case (true, true), (false, false):
            return self
        }
    }

}
