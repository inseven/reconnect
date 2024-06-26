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

import Diligence
import Interact

struct ContentView: View {

    var applicationModel: ApplicationModel
    let fileServer = FileServer(host: "127.0.0.1", port: 7501)

    var body: some View {
        if applicationModel.isConnected {
            BrowserView(fileServer: fileServer)
        } else {
            ContentUnavailableView("Not Connected", systemImage: "star")
        }
    }

}


@main
struct ReconnectApp: App {

    static let title = "Reconnect Support (\(Bundle.main.extendedVersion ?? "Unknown Version"))"

    @State var server = Server()
    @State var applicationModel: ApplicationModel

    init() {
        self.applicationModel = ApplicationModel()
    }

    var body: some Scene {

        MenuBarExtra {
            MainMenu()
                .environment(applicationModel)
        } label: {
            if applicationModel.isConnected {
                Image("StatusConnected")
            } else {
                Image("StatusDisconnected")
            }
        }

        WindowGroup {
            ContentView(applicationModel: applicationModel)
        }
        .environment(applicationModel)
        .handlesExternalEvents(matching: [.browser])

        About(repository: "inseven/reconnect", copyright: "Copyright © 2024 Jason Morley") {
            Action("GitHub", url: URL(string: "https://github.com/inseven/reconnect")!)
        } acknowledgements: {
            Acknowledgements("Developers") {
                Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
            }
            Acknowledgements("Thanks") {
                Credit("George Wright")
                Credit("Lukas Fittl")
                Credit("Sarah Barbour")
            }
        } licenses: {
            (.reconnect)
        }
        .handlesExternalEvents(matching: [.about])

    }

}
