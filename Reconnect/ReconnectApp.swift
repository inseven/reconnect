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
import PsionSoftwareIndex

@main @MainActor
struct ReconnectApp: App {

    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    static let title = "Reconnect Support (\(Bundle.main.extendedVersion ?? "Unknown Version"))"

    var body: some Scene {

        BrowserWindow(applicationModel: appDelegate.applicationModel, transfersModel: appDelegate.transfersModel)

        TransfersWindow()
            .environment(appDelegate.applicationModel)
            .environment(appDelegate.transfersModel)

        PsionSoftwareIndexWindow()
            .environment(appDelegate.applicationModel)
            .environment(appDelegate.transfersModel)
            .handlesExternalEvents(matching: [.psionSoftwareIndex])
            .onDownloadItem { item in
                do {
                    let url = try FileManager.default.safelyMoveItem(at: item.url, toDirectory: .downloadsDirectory)
                    appDelegate.applicationModel.showInstallerWindow(url: url)
                } catch {
                    print("Failed to handle download with error \(error).")
                }
            }

        ProgramManagerWindow()
            .environment(appDelegate.applicationModel)
            .environment(appDelegate.transfersModel)
            .handlesExternalEvents(matching: [.programManager])

        Settings {
            SettingsView(applicationModel: appDelegate.applicationModel)
        }

        About(repository: "inseven/reconnect", copyright: "Copyright © 2024-2025 Jason Morley") {
            Action("Website", url: .website)
            Action("Privacy Policy", url: .privacyPolicy)
            Action("GitHub", url: .gitHub)
            Action("Support", url: .support)
        } acknowledgements: {
            Acknowledgements("Developers") {
                Credit("Jason Morley", url: URL(string: "https://jbmorley.co.uk"))
                Credit("Tom Sutcliffe", url: URL(string: "https://github.com/tomsci"))
            }
            Acknowledgements("Thanks") {
                Credit("Alex Brown")
                Credit("Fabrice Cappaert")
                Credit("George Wright")
                Credit("Lukas Fittl")
                Credit("Matt Sephton")
                Credit("Sarah Barbour")
                Credit("Tom Sutcliffe")
            }
        } licenses: {
            (.reconnect)
        }
        .handlesExternalEvents(matching: [.about])

    }

}
