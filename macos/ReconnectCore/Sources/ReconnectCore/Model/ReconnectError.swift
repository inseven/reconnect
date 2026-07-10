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

import Foundation

import plptools

public enum ReconnectError: Error {
    case unknown
    case invalidFilePath
    case unknownFileSize
    case imageSaveError
    case invalidLocalization
    case invalidSisFile
    case invalidFileReference
    case missingTools
    case invalidDaemonProxy
    case configurationDencodeError
    case configurationEncodeError
    case cancelled
    case unknownDownloadFailure
    case unsupportedImageFormat
    case directoryListingError
    case epocError(PLPToolsError)
    case transferError(PLPToolsError, String, String)
    case existenceCheckError(PLPToolsError, String)
    case createDirectoryError(PLPToolsError, String)
    case extendedAttributesError(PLPToolsError, String)
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
        case .invalidFileReference:
            return "Invalid file reference."
        case .missingTools:
            return "The Reconnect Tools are not installed on your Psion."
        case .invalidDaemonProxy:
            return "Failed to get daemon proxy."
        case .configurationDencodeError:
            return "Failed to decode device configuration."
        case .configurationEncodeError:
            return "Failed to encode device configuration."
        case .cancelled:
            return "Cancelled."
        case .unknownDownloadFailure:
            return "Unknown download failure."
        case .unsupportedImageFormat:
            return "Unsupported image format."
        case .directoryListingError:
            return "Failed to list directory."
        case .epocError(let epocError):
            return epocError.errorDescription
        case .transferError(let epocError, let source, let destination):
            if let description = epocError.errorDescription {
                return "Failed to transfer file '\(source)' to '\(destination)' with error '\(description)'."
            } else {
                return "Failed to upload file '\(source)' to '\(destination)'."
            }
        case .existenceCheckError(let epocError, let path):
            if let description = epocError.errorDescription {
                return "Failed to check file '\(path)' exists with error '\(description)'."
            } else {
                return "Failed to check file '\(path)' exists."
            }
        case .createDirectoryError(let epocError, let path):
            if let description = epocError.errorDescription {
                return "Failed to create directory '\(path)' with error '\(description)'."
            } else {
                return "Failed to create directory '\(path)'."
            }
        case .extendedAttributesError(let epocError, let path):
            if let description = epocError.errorDescription {
                return "Failed to get extended attributes for file '\(path)' with error '\(description)'."
            } else {
                return "Failed to get extended attributes for file '\(path)'."
            }
        }
    }

}

extension ReconnectError {

    public var mappedToEpocErrorCode: Int32 {
        switch self {
        case .unknown:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .invalidFilePath:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .unknownFileSize:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .imageSaveError:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .invalidLocalization:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .invalidSisFile:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .invalidFileReference:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .missingTools:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .invalidDaemonProxy:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .configurationDencodeError:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .configurationEncodeError:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .cancelled:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .unknownDownloadFailure:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .unsupportedImageFormat:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .directoryListingError:
            return PLPToolsError.E_PSI_GEN_FAIL.rawValue
        case .epocError(let epocError):
            return epocError.rawValue
        case .transferError(let epocError, _, _):
            return epocError.rawValue
        case .existenceCheckError(let epocError, _):
            return epocError.rawValue
        case .createDirectoryError(let epocError, _):
            return epocError.rawValue
        case .extendedAttributesError(let epocError, _):
            return epocError.rawValue
        }
    }

}
