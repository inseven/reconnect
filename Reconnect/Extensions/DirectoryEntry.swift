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

    var fileType: FileType {
        if isDirectory {
            return .directory
        } else {
            switch uid3 {
            case .word:
                return .word
            case .sheet:
                return .sheet
            case .record:
                return .record
            case .opl:
                return .opl
            case .data:
                return .data
            case .agenda:
                return .agenda
            case .sketch:
                return .sketch
            case .jotter:
                return .jotter
            default:
                return .unknown
            }
        }
    }

    var image: String {
        if isDirectory {
            return "Folder16"
        } else {
            switch uid3 {
            case .word:
                return "Word16"
            case .sheet:
                return "Sheet16"
            case .record:
                return "Record16"
            case .opl:
                return "OPL16"
            case .data:
                return "Data16"
            case .agenda:
                return "Agenda16"
            case .sketch:
                return "Sketch16"
            case .jotter:
                return "Jotter16"
            default:
                return "FileUnknown16"
            }
        }

    }

}
