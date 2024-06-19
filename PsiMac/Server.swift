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

struct Server {

    func threadEntryPoint() {

        let arguments = ["ncpd", "-d", "-s", "/dev/tty.usbserial-A91MGK6M", "-b", "115200", "-v", "nl"]

        let argc = Int32(arguments.count)
        var argv: [UnsafeMutablePointer<CChar>?] = arguments.map { strdup($0) }
        argv.append(nil)  // Null-terminate the array

        // Convert the array to an UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
        let argvPointer = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: argv.count)
        argvPointer.initialize(from: &argv, count: argv.count)

        // Call the C function
        let result = run(argc, argvPointer)
        print(result)

        // Free the memory allocated for the C strings
        for arg in argv {
            free(arg)
        }
        argvPointer.deallocate()

    }

    init() {
        // Create a new thread and start it
        let thread = Thread(block: threadEntryPoint)
        thread.start()
    }

}
