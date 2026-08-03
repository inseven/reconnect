// Reconnect -- Psion connectivity for macOS
 //
 // Copyright (C) 2023-2026 Jason Morley, Tom Sutcliffe
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

public enum StringEncoding {
    case stringEncoding(String.Encoding)
    case cfStringEncoding(CFStringEncodings)
}

extension String {

    init?(cString: UnsafePointer<CChar>, encoding: StringEncoding) {
        switch encoding {
        case .stringEncoding(let enc):
            self.init(cString: cString, encoding: enc)
        case .cfStringEncoding(let enc):
            let nsenc =  CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(enc.rawValue))
            if let nsstring = NSString(cString: cString, encoding: nsenc) {
                self.init(nsstring)
            } else {
                return nil
            }
        }
    }

    func cString(using encoding: StringEncoding) -> [CChar]? {
        switch encoding {
        case .stringEncoding(let enc):
            return self.cString(using: enc)
        case .cfStringEncoding(let enc):
            let nsstring = self as NSString
            let nsencoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(enc.rawValue))
            guard let unsafePointer = nsstring.cString(using: nsencoding) else {
                return nil
            }
            return Array(UnsafeBufferPointer(start: unsafePointer, count: strlen(unsafePointer) + 1))
        }
    }

}
