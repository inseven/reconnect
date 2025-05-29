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

import UniformTypeIdentifiers
import os

final class InstallerDocument: ReferenceFileDocument {
    
    struct Storage {
        var contents: Data
    }
    
    static let readableContentTypes: [UTType] = [.sis]
    static let writeableContentTypes: [UTType] = []
    
    let storage: OSAllocatedUnfairLock<Storage>
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.storage = .init(initialState: .init(contents: data))
    }
    
    func snapshot(contentType: UTType) throws -> Data {
        storage.withLock { $0.contents }
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: snapshot)
    }

}
