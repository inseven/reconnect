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

import Diligence

@main @MainActor
struct ReconnectApp: App {

    static let title = "Reconnect Support (\(Bundle.main.extendedVersion ?? "Unknown Version"))"

    @State var transfersModel = TransfersModel()
    @State var applicationModel = ApplicationModel()

    var body: some Scene {

        BrowserWindow(applicationModel: applicationModel, transfersModel: transfersModel)

        TransfersWindow()
            .environment(applicationModel)
            .environment(transfersModel)

        About(repository: "inseven/reconnect", copyright: "Copyright © 2024-2025 Jason Morley") {
            Action("GitHub", url: .gitHub)
            Action("Discord", url: .discord)
            Action("Support", url: .support)
        } acknowledgements: {
            Acknowledgements("Developers") {
                Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
            }
            Acknowledgements("Thanks") {
                Credit("Alex Brown")
                Credit("Fabrice Cappaert")
                Credit("George Wright")
                Credit("Lukas Fittl")
                Credit("Sarah Barbour")
                Credit("Tom Sutcliffe")
            }
        } licenses: {
            (.reconnect)
        }
        .handlesExternalEvents(matching: [.about])

    }

}
