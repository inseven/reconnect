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

class FileManageableProxy: ObservableObject, FileManageable {

    var canOpenSelection: Bool {
        return _canOpenSelection()
    }

    var canCreateNewFolder: Bool {
        return _canCreateNewFolder()
    }

    var canDelete: Bool {
        return _canDelete()
    }

    var canDownload: Bool {
        return _canDownload()
    }

    private let _canOpenSelection: @MainActor () -> Bool
    private let _openSelection: @MainActor () -> Void
    private let _canCreateNewFolder: @MainActor () -> Bool
    private let _createNewFolder: @MainActor () -> Void
    private let _canDelete: @MainActor () -> Bool
    private let _delete: @MainActor () -> Void
    private let _canDownload: @MainActor () -> Bool
    private let _download: @MainActor () -> Void

    init(_ fileManageable: FileManageable) {
        _canOpenSelection = {
            return fileManageable.canOpenSelection
        }
        _openSelection = {
            fileManageable.openSelection()
        }
        _canCreateNewFolder = {
            return fileManageable.canCreateNewFolder
        }
        _createNewFolder = {
            fileManageable.createNewFolder()
        }
        _canDelete = {
            return fileManageable.canDelete
        }
        _delete = {
            fileManageable.delete()
        }
        _canDownload = {
            return fileManageable.canDownload
        }
        _download = {
            fileManageable.download()
        }
    }

    func openSelection() {
        _openSelection()
    }

    func createNewFolder() {
        _createNewFolder()
    }

    func delete() {
        _delete()
    }

    func download() {
        _download()
    }

}
