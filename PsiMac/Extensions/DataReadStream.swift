// PsiMac -- Psion connectivity for macOS
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

import DataStream

extension DataReadStream {

    func readLE() throws -> UInt32 {
        let value = try readBytes() as UInt32
        return CFSwapInt32LittleToHost(value)
    }

    func readLE() throws -> UInt16 {
        let value = try readBytes() as UInt16
        return CFSwapInt16LittleToHost(value)
    }


    public func read(length: Int) throws -> String {
        let data = try read(count: length)
        guard let result = String(data: data, encoding: .ascii) else {
            throw PsiMacError.invalidString
        }
        return result
    }

}
