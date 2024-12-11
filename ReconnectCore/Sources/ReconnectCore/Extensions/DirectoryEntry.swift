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

import Foundation

extension FileServer.DirectoryEntry {

    public var fileType: FileType {
        if isDirectory {
            return .directory
        } else {
            switch (uid1, uid2, uid3) {
            case (.directFileStore, .appDllDoc, .word):
                return .word
            case (.directFileStore, .appDllDoc, .sheet):
                return .sheet
            case (.directFileStore, .appDllDoc, .record):
                return .record
            case (.directFileStore, .appDllDoc, .opl):
                return .opl
            case (.permanentFileStoreLayout, .appDllDoc, .data):
                return .data
            case (.permanentFileStoreLayout, .appDllDoc, .agenda):
                return .agenda
            case (.directFileStore, .appDllDoc, .sketch):
                return .sketch
            case (.permanentFileStoreLayout, .appDllDoc, .jotter):
                return .jotter
            case  (.directFileStore, .mbm, .none), (.multiBitmapRomImage, .none, .none):
                return .mbm
            default:
                return .unknown
            }
        }
    }
    
    public var pathExtension: String {
        return (self.name as NSString).pathExtension
    }

}
