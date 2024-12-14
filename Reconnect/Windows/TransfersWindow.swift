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

import SwiftUI

import Interact

struct TransfersWindow: Scene {

    static let id = "transfers"

    @Environment(TransfersModel.self) private var transfersModel

    var body: some Scene {
        Window("Transfers", id: Self.id) {
            TransfersView(transfersModel: transfersModel)
                .onOpenURL { url in
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let path = components.queryItems?.first(where: { $0.name == "path" })?.value,
                          let installerURL = URL(string: path),
                          installerURL.scheme == "file"
                    else {
                        return
                    }
                    let filename = installerURL.lastPathComponent
                    Task {
                        try? await transfersModel.upload(from: installerURL, to: "C:".appendingWindowsPathComponent(filename))
                    }
                }
                .handlesExternalEvents(preferring: [.install], allowing: [])
        }
        .windowResizability(.contentSize)
        .handlesExternalEvents(matching: [.install, .transfers])
    }

}
