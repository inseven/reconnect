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

extension RemoteCommandServicesClient.MachineType {

    public var isEpoc32: Bool {
        switch self {
        case .PSI_MACH_S5, .PSI_MACH_WINC:
            return true
        default:
            return false
        }
    }

    public var localizedNameKey: LocalizedStringKey {
        switch self {
        case .PSI_MACH_UNKNOWN:
            return "Unknown"
        case .PSI_MACH_PC:
            return "PC"
        case .PSI_MACH_MC:
            return "MC"
        case .PSI_MACH_HC:
            return "HC"
        case .PSI_MACH_S3:
            return "Series 3"
        case .PSI_MACH_S3A:
            return "Series 3a / Series 3c / Series 3mx"
        case .PSI_MACH_WORKABOUT:
            return "Workabout"
        case .PSI_MACH_SIENNA:
            return "Siena"
        case .PSI_MACH_S3C:
            return "Series 3c"
        case .PSI_MACH_S5:
            return "Series 5 / Series 5mx / Series 7 / netBook"
        case .PSI_MACH_WINC:
            return "WinC"
        }

    }

}
