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

import Foundation

public enum FileType {

    case unknown
    case directory
    case word
    case sheet
    case record
    case opl
    case data
    case agenda
    case sketch
    case jotter
    case mbm

}

extension FileType {

    public var name: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .directory:
            return "Folder"
        case .word:
            return "Word"
        case .sheet:
            return "Sheet"
        case .record:
            return "Record"
        case .opl:
            return "OPL"
        case .data:
            return "Data"
        case .agenda:
            return "Agenda"
        case .sketch:
            return "Sketch"
        case .jotter:
            return "Jotter"
        case .mbm:
            return "Bitmap"
        }
    }

    public var image: String {
        switch self {
        case .unknown:
            return "FileUnknown16"
        case .directory:
            return "Folder16"
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
        case .mbm:
            return "FileUnknown16"
        }
    }

}
