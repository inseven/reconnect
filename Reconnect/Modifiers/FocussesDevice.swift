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

import SwiftUI

// This is somewhat of a hack to ensure we focus the connected in advance of a full rework to ensure the device is
// correctly injected into the view hierarchy.
struct FocusesDevice: ViewModifier {

    @Environment(ApplicationModel.self) private var applicationModel

    func body(content: Content) -> some View {
        if let deviceModel = applicationModel.devices.first {
            content
                .environment(deviceModel)
                .focusedSceneObject(DeviceModelProxy(deviceModel: deviceModel))
        } else {
            EmptyView()
        }
    }

}

extension View {

    func focusesDevice() -> some View {
        return modifier(FocusesDevice())
    }

}
