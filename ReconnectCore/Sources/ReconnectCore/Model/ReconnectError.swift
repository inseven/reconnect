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

import ncp

public enum ReconnectError: Error {
    case unknown
    case invalidFilePath
    case unknownFileSize
    case imageSaveError
    case invalidLocalization
    case invalidSisFile
}

extension ReconnectError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error."
        case .invalidFilePath:
            return "Invalid file path."
        case .unknownFileSize:
            return "Unknown file size."
        case .imageSaveError:
            return "Failed to save image."
        case .invalidLocalization:
            return "Badly formatted localized text."
        case .invalidSisFile:
            return "Invalid SIS file."
        }
    }

}
