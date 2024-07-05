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

import SwiftUI

extension UInt32 {

    static let word: Self = 0x1000007F
    static let sheet: Self = 0x10000088
    static let record: Self = 0x1000007E
    static let opl: Self = 0x10000085
    static let data: Self = 0x10000086
    static let agenda: Self = 0x10000084
    static let sketch: Self = 0x1000007D
    static let jotter: Self = 0x10000CEA

}