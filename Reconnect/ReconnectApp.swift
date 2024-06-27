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
import Sparkle

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater

        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
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
