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

import Foundation

import plptools

// TODO: localizedDescription
// TODO: Not sure this is a FileServerError?
// TODO: It might be better if this weren't the error itself.
public enum FileServerError: Int32, Error {
//    case none = 0
    case general = -1
    case badArgument = -2
    case osError = -3
    case notSupported = -4
    case underflow = -5
    case overflow = -6
    case outOfRange = -7
    case divideByZero = -8
    case inUse = -9
    case outOfMemory = -10
    case outOfSegments = -11
    case outOfSemaphores = -12
    case outOfProcesses = -13
    case alreadyOpen = -14
    case notOpen = -15
    case badImage = -16
    case receiveError = -17
    case deviceError = -18
    case noFilesystem = -19
    case notReady = -20
    case noFont = -21
    case tooWide = -22
    case tooMany = -23
    case fileAlreadyExists = -32
    case noSuchFile = -33
    case writeError = -34
    case readError = -35
    case endOfFile = -36
    case readBufferFull = -37
    case invalidFileName = -38
    case accessDenied = -39
    case resourceLocked = -40
    case noSuchDevice = -41
    case noSuchDirectory = -42
    case noSuchRecord = -43
    case fileIsReadOnly = -44
    case invalidIOOperation = -45
    case ioPending = -46
    case invalidVolumeName = -47
    case cancelled = -48
    case noMemoryForControlBlock = -49
    case unitDisconnected = -50
    case alreadyConnected = -51
    case retransmissionThresholdExceeded = -52
    case physicalLinkFailure = -53
    case inactivityTimerExpired = -54
    case serialParityError = -55
    case serialFramingError = -56
    case serialOverrunError = -57
    case modemCannotConnectToRemoteModem = -58
    case remoteModemBusy = -59
    case remoteModemDidNotAnswer = -60
    case numberBlacklistedByTheModem = -61
    case driveNotReady = -62
    case unknownMedia = -63
    case directoryFull = -64
    case writeProtected = -65
    case mediaCorrupt = -66
    case abortedOperation = -67
    case failedToEraseFlashMedia = -68
    case invalidFileForDBFSystem = -69
    case powerFailure = -100
    case tooBig = -101
    case badDescriptor = -102
    case badEntryPoint = -103
    case couldNotDisconnect = -104
    case badDriver = -105
    case operationNotCompleted = -106
    case serverBusy = -107
    case terminated = -108
    case died = -109
    case badHandle = -110
}

extension rfsv.errs {

    public var localizedDescription: String {
        switch self.rawValue {
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
            return "Cancelled"
        case -49:  // E_PSI_FILE_ALLOC
            return "No memory for control block"
        case -50:  // E_PSI_FILE_DISC
            return "Unit disconnected"
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
            return "Rumber blacklisted by the modem"
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
            return "Remote file server error (\(self.rawValue))"
        }
    }

    // TODO: THis should probaby be able to return an unknown plptools error.
    public func check() throws(FileServerError) {
        guard self.rawValue != 0 else {
            return
        }
        throw FileServerError(rawValue: self.rawValue)!
    }

}
