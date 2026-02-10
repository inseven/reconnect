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

import ncp

public typealias PLPToolsError = rfsv.errs

extension PLPToolsError: @retroactive _BridgedNSError {}
extension PLPToolsError: @retroactive _ObjectiveCBridgeableError {}

extension PLPToolsError: @retroactive LocalizedError {

    public var errorDescription: String? {
        switch self {
        case  .E_PSI_GEN_NONE:
            return "None"
        case .E_PSI_GEN_FAIL:
            return "General"
        case .E_PSI_GEN_ARG:
            return "Bad argument"
        case .E_PSI_GEN_OS:
            return "OS error"
        case .E_PSI_GEN_NSUP:
            return "Not supported"
        case .E_PSI_GEN_UNDER:
            return "Underflow"
        case .E_PSI_GEN_OVER:
            return "Overflow"
        case .E_PSI_GEN_RANGE:
            return "Out of range"
        case .E_PSI_GEN_DIVIDE:
            return "Divide by zero"
        case .E_PSI_GEN_INUSE:
            return "In use"
        case  .E_PSI_GEN_NOMEMORY:
            return "Out of memory"
        case .E_PSI_GEN_NOSEGMENTS:
            return "Out of segments"
        case .E_PSI_GEN_NOSEM:
            return "Out of semaphores"
        case .E_PSI_GEN_NOPROC:
            return "Out of processes"
        case .E_PSI_GEN_OPEN:
            return "Already open"
        case .E_PSI_GEN_NOTOPEN:
            return "Not open"
        case .E_PSI_GEN_IMAGE:
            return "Bad image"
        case .E_PSI_GEN_RECEIVER:
            return "Receive error"
        case .E_PSI_GEN_DEVICE:
            return "Device error"
        case .E_PSI_GEN_FSYS:
            return "No filesystem"
        case .E_PSI_GEN_START:
            return "Not ready"
        case .E_PSI_GEN_NOFONT:
            return "No font"
        case .E_PSI_GEN_TOOWIDE:
            return "Too wide"
        case .E_PSI_GEN_TOOMANY:
            return "Too many"
        case .E_PSI_FILE_EXIST:
            return "File already exists"
        case .E_PSI_FILE_NXIST:
            return "No such file"
        case .E_PSI_FILE_WRITE:
            return "Write error"
        case .E_PSI_FILE_READ:
            return "Read error"
        case .E_PSI_FILE_EOF:
            return "End of file"
        case .E_PSI_FILE_FULL:
            return "Disk/serial read buffer full"
        case .E_PSI_FILE_NAME:
            return "Invalid file name"
        case .E_PSI_FILE_ACCESS:
            return "Access denied"
        case .E_PSI_FILE_LOCKED:
            return "Resource locked"
        case .E_PSI_FILE_DEVICE:
            return "No such device"
        case .E_PSI_FILE_DIR:
            return "No such directory"
        case .E_PSI_FILE_RECORD:
            return "No such record"
        case .E_PSI_FILE_RDONLY:
            return "File is read-only"
        case .E_PSI_FILE_INV:
            return "Invalid I/O operation"
        case .E_PSI_FILE_PENDING:
            return "I/O pending (not yet completed)"
        case .E_PSI_FILE_VOLUME:
            return "Invalid volume name"
        case .E_PSI_FILE_CANCEL:
            return "Canceled"
        case .E_PSI_FILE_ALLOC:
            return "No memory for control block"
        case .E_PSI_FILE_DISC:
            return "Disconnected"
        case .E_PSI_FILE_CONNECT:
            return "Already connected"
        case .E_PSI_FILE_RETRAN:
            return "Retransmission threshold exceeded"
        case .E_PSI_FILE_LINE:
            return "Physical link failure"
        case .E_PSI_FILE_INACT:
            return "Inactivity timer expired"
        case .E_PSI_FILE_PARITY:
            return "Serial parity error"
        case .E_PSI_FILE_FRAME:
            return "Serial framing error"
        case .E_PSI_FILE_OVERRUN:
            return "Serial overrun error"
        case .E_PSI_MDM_CONFAIL:
            return "Modem cannot connect to remote modem"
        case .E_PSI_MDM_BUSY:
            return "Remote modem busy"
        case .E_PSI_MDM_NOANS:
            return "Remote modem did not answer"
        case .E_PSI_MDM_BLACKLIST:
            return "Number disallowed by the modem"
        case .E_PSI_FILE_NOTREADY:
            return "Drive not ready"
        case .E_PSI_FILE_UNKNOWN:
            return "Unknown media"
        case .E_PSI_FILE_DIRFULL:
            return "Directory full"
        case .E_PSI_FILE_PROTECT:
            return "Write-protected"
        case .E_PSI_FILE_CORRUPT:
            return "Media corrupt"
        case .E_PSI_FILE_ABORT:
            return "Aborted operation"
        case .E_PSI_FILE_ERASE:
            return "Failed to erase flash media"
        case .E_PSI_FILE_INVALID:
            return "Invalid file for DBF system"
        case .E_PSI_GEN_POWER:
            return "Power failure"
        case .E_PSI_FILE_TOOBIG:
            return "Too big"
        case .E_PSI_GEN_DESCR:
            return "Dad descriptor"
        case .E_PSI_GEN_LIB:
            return "Bad entry point"
        case .E_PSI_FILE_NDISC:
            return "Could not disconnect"
        case .E_PSI_FILE_DRIVER:
            return "Bad driver"
        case .E_PSI_FILE_COMPLETION:
            return "Operation not completed"
        case .E_PSI_GEN_BUSY:
            return "Server busy"
        case .E_PSI_GEN_TERMINATED:
            return "Terminated"
        case .E_PSI_GEN_DIED:
            return "Died"
        case .E_PSI_FILE_HANDLE:
            return "Bad handle"

        // Special error codes.
        case .E_PSI_NOT_SIBO:
            return "Operation not permitted in EPOC16"
        case .E_PSI_INTERNAL:
            return "Internal error"
        }
    }

}
