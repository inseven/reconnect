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

import Interact

import ReconnectCore

class NSRestoreWindow: NSWindow {

    var backup: Backup?

    convenience init(applicationModel: ApplicationModel, backup: Backup) {
        let windowProxy = WindowProxy()
        let rootView = RestoreView(applicationModel: applicationModel, backup: backup)
            .environment(applicationModel)
            .environment(\.window, windowProxy)
        self.init(contentViewController: NSHostingController(rootView: rootView))
        self.backup = backup
        windowProxy.nsWindow = self
        title = "Restore"
        styleMask.remove([.closable, .resizable, .borderless, .fullSizeContentView])
        setContentSize(.wizard)
    }

}
