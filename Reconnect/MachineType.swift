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

enum MachineType: UInt32 {
    case unknown = 0
    case PSI_MACH_PC = 1
    case PSI_MACH_MC = 2
    case PSI_MACH_HC = 3
    case psionSeries3 = 4
    case psionSeries3a = 5
    case psionWorkabout = 6
    case psionSienna = 7
    case psionSeries3c = 8
    case psionSeries5 = 32
    case psionWinC = 33

}
