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

import SwiftUI

// This approach feels fairly messy, but I can't think of a better way to do it as the `.handlesExternalEvents` modifier
// doesn't appear to work on the SwiftUI `Settings` scene. This view modifier is therefore expected to be used on the
// main window and uses the new `.openSettings` environment key to, after a short delay to allow the main window to be
// created, open the settings. Hopefully this is fixed in the future.
fileprivate struct OpensSettings: ViewModifier {

    @Environment(\.openSettings) private var openSettings

    @Environment(ApplicationModel.self) private var applicationModel

    static let settingsURLs: Set<URL> = [.settings, .settingsGeneral, .settingsDevices]

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard Self.settingsURLs.contains(url) else {
                    return
                }
                if url == .settings || url == .settingsGeneral {
                    applicationModel.activeSettingsSection = .general
                } else if url == .settingsDevices {
                    applicationModel.activeSettingsSection = .devices
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    openSettings()
                }
            }
            .handlesExternalEvents(preferring: Self.settingsURLs, allowing: Self.settingsURLs)
    }

}

extension View {

    func opensSettings() -> some View {
        return modifier(OpensSettings())
    }

}
