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

public func LocalizedEpoc32ErrorCode(_ code: Int32) -> String {
    switch code {
    case  0:  // E_PSI_GEN_NONE
        return "None"
    case -1:  // E_PSI_GEN_FAIL
        return "General"
    case -2:  // E_PSI_GEN_ARG
        return "Bad argument"
    case -3:  // E_PSI_GEN_OS
        return "OS error"
    case -4:  // E_PSI_GEN_NSUP
        return "Not supported"
    case -5:  // E_PSI_GEN_UNDER
        return "Underflow"
    case -6:  // E_PSI_GEN_OVER
        return "Overflow"
    case -7:  // E_PSI_GEN_RANGE
        return "Out of range"
    case -8:  // E_PSI_GEN_DIVIDE
        return "Divide by zero"
    case -9:  // E_PSI_GEN_INUSE
        return "In use"
    case  10:  // E_PSI_GEN_NOMEMORY
        return "Out of memory"
    case -11:  // E_PSI_GEN_NOSEGMENTS
        return "Out of segments"
    case -12:  // E_PSI_GEN_NOSEM
        return "Out of semaphores"
    case -13:  // E_PSI_GEN_NOPROC
        return "Out of processes"
    case -14:  // E_PSI_GEN_OPEN
        return "Already open"
    case -15:  // E_PSI_GEN_NOTOPEN
        return "Not open"
    case -16:  // E_PSI_GEN_IMAGE
        return "Bad image"
    case -17:  // E_PSI_GEN_RECEIVER
        return "Receive error"
    case -18:  // E_PSI_GEN_DEVICE
        return "Device error"
    case -19:  // E_PSI_GEN_FSYS
        return "No filesystem"
    case -20:  // E_PSI_GEN_START
        return "Not ready"
    case -21:  // E_PSI_GEN_NOFONT
        return "No font"
    case -22:  // E_PSI_GEN_TOOWIDE
        return "Too wide"
    case -23:  // E_PSI_GEN_TOOMANY
        return "Too many"
    case -32:  // E_PSI_FILE_EXIST
        return "File already exists"
    case -33:  // E_PSI_FILE_NXIST
        return "No such file"
    case -34:  // E_PSI_FILE_WRITE
        return "Write error"
    case -35:  // E_PSI_FILE_READ
        return "Read error"
    case -36:  // E_PSI_FILE_EOF
        return "End of file"
    case -37:  // E_PSI_FILE_FULL
        return "Disk/serial read buffer full"
    case -38:  // E_PSI_FILE_NAME
        return "Invalid file name"
    case -39:  // E_PSI_FILE_ACCESS
        return "Access denied"
    case -40:  // E_PSI_FILE_LOCKED
        return "Resource locked"
    case -41:  // E_PSI_FILE_DEVICE
        return "No such device"
    case -42:  // E_PSI_FILE_DIR
        return "No such directory"
    case -43:  // E_PSI_FILE_RECORD
        return "No such record"
    case -44:  // E_PSI_FILE_RDONLY
        return "File is read-only"
    case -45:  // E_PSI_FILE_INV
        return "Invalid I/O operation"
    case -46:  // E_PSI_FILE_PENDING
        return "I/O pending (not yet completed)"
    case -47:  // E_PSI_FILE_VOLUME
        return "Invalid volume name"
    case -48:  // E_PSI_FILE_CANCEL
        return "Canceled"
    case -49:  // E_PSI_FILE_ALLOC
        return "No memory for control block"
    case -50:  // E_PSI_FILE_DISC
        return "Disconnected"
    case -51:  // E_PSI_FILE_CONNECT
        return "Already connected"
    case -52:  // E_PSI_FILE_RETRAN
        return "Retransmission threshold exceeded"
    case -53:  // E_PSI_FILE_LINE
        return "Physical link failure"
    case -54:  // E_PSI_FILE_INACT
        return "Inactivity timer expired"
    case -55:  // E_PSI_FILE_PARITY
        return "Serial parity error"
    case -56:  // E_PSI_FILE_FRAME
        return "Serial framing error"
    case -57:  // E_PSI_FILE_OVERRUN
        return "Serial overrun error"
    case -58:  // E_PSI_MDM_CONFAIL
        return "Modem cannot connect to remote modem"
    case -59:  // E_PSI_MDM_BUSY
        return "Remote modem busy"
    case -60:  // E_PSI_MDM_NOANS
        return "Remote modem did not answer"
    case -61:  // E_PSI_MDM_BLACKLIST
        return "Number disallowed by the modem"
    case -62:  // E_PSI_FILE_NOTREADY
        return "Drive not ready"
    case -63:  // E_PSI_FILE_UNKNOWN
        return "Unknown media"
    case -64:  // E_PSI_FILE_DIRFULL
        return "Directory full"
    case -65:  // E_PSI_FILE_PROTECT
        return "Write-protected"
    case -66:  // E_PSI_FILE_CORRUPT
        return "Media corrupt"
    case -67:  // E_PSI_FILE_ABORT
        return "Aborted operation"
    case -68:  // E_PSI_FILE_ERASE
        return "Failed to erase flash media"
    case -69:  // E_PSI_FILE_INVALID
        return "Invalid file for DBF system"
    case -100:  // E_PSI_GEN_POWER
        return "Power failure"
    case -101:  // E_PSI_FILE_TOOBIG
        return "Too big"
    case -102:  // E_PSI_GEN_DESCR
        return "Dad descriptor"
    case -103:  // E_PSI_GEN_LIB
        return "Bad entry point"
    case -104:  // E_PSI_FILE_NDISC
        return "Could not disconnect"
    case -105:  // E_PSI_FILE_DRIVER
        return "Bad driver"
    case -106:  // E_PSI_FILE_COMPLETION
        return "Operation not completed"
    case -107:  // E_PSI_GEN_BUSY
        return "Server busy"
    case -108:  // E_PSI_GEN_TERMINATED
        return "Terminated"
    case -109:  // E_PSI_GEN_DIED
        return "Died"
    case -110:  // E_PSI_FILE_HANDLE
        return "Bad handle"
    default:
        return "Unknown EPOC32 error code (\(code))"
    }
}
