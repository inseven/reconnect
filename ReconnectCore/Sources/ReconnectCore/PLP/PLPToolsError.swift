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

public enum PLPToolsError: Int32, Error {
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

    case unknown = -999
}

extension PLPToolsError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .general:
            return "General"
        case .badArgument:
            return "Bad argument"
        case .osError:
            return "OS error"
        case .notSupported:
            return "Not supported"
        case .underflow:
            return "Underflow"
        case .overflow:
            return "Overflow"
        case .outOfRange:
            return "Out of range"
        case .divideByZero:
            return "Divide by zero"
        case .inUse:
            return "In use"
        case .outOfMemory:
            return "Out of memory"
        case .outOfSegments:
            return "Out of segments"
        case .outOfSemaphores:
            return "Out of semaphores"
        case .outOfProcesses:
            return "Out of processes"
        case .alreadyOpen:
            return "Already open"
        case .notOpen:
            return "Not open"
        case .badImage:
            return "Bad image"
        case .receiveError:
            return "Receive error"
        case .deviceError:
            return "Device error"
        case .noFilesystem:
            return "No filesystem"
        case .notReady:
            return "Not ready"
        case .noFont:
            return "No font"
        case .tooWide:
            return "Too wide"
        case .tooMany:
            return "Too many"
        case .fileAlreadyExists:
            return "File already exists"
        case .noSuchFile:
            return "No such file"
        case .writeError:
            return "Write error"
        case .readError:
            return "Read error"
        case .endOfFile:
            return "End of file"
        case .readBufferFull:
            return "Disk/serial read buffer full"
        case .invalidFileName:
            return "Invalid file name"
        case .accessDenied:
            return "Access denied"
        case .resourceLocked:
            return "Resource locked"
        case .noSuchDevice:
            return "No such device"
        case .noSuchDirectory:
            return "No such directory"
        case .noSuchRecord:
            return "No such record"
        case .fileIsReadOnly:
            return "File is read-only"
        case .invalidIOOperation:
            return "Invalid I/O operation"
        case .ioPending:
            return "I/O pending (not yet completed)"
        case .invalidVolumeName:
            return "Invalid volume name"
        case .cancelled:
            return "Cancelled"
        case .noMemoryForControlBlock:
            return "No memory for control block"
        case .unitDisconnected:
            return "Unit disconnected"
        case .alreadyConnected:
            return "Already connected"
        case .retransmissionThresholdExceeded:
            return "Retransmission threshold exceeded"
        case .physicalLinkFailure:
            return "Physical link failure"
        case .inactivityTimerExpired:
            return "Inactivity timer expired"
        case .serialParityError:
            return "Serial parity error"
        case .serialFramingError:
            return "Serial framing error"
        case .serialOverrunError:
            return "Serial overrun error"
        case .modemCannotConnectToRemoteModem:
            return "Modem cannot connect to remote modem"
        case .remoteModemBusy:
            return "Remote modem busy"
        case .remoteModemDidNotAnswer:
            return "Remote modem did not answer"
        case .numberBlacklistedByTheModem:
            return "Rumber blacklisted by the modem"
        case .driveNotReady:
            return "Drive not ready"
        case .unknownMedia:
            return "Unknown media"
        case .directoryFull:
            return "Directory full"
        case .writeProtected:
            return "Write-protected"
        case .mediaCorrupt:
            return "Media corrupt"
        case .abortedOperation:
            return "Aborted operation"
        case .failedToEraseFlashMedia:
            return "Failed to erase flash media"
        case .invalidFileForDBFSystem:
            return "Invalid file for DBF system"
        case .powerFailure:
            return "Power failure"
        case .tooBig:
            return "Too big"
        case .badDescriptor:
            return "Dad descriptor"
        case .badEntryPoint:
            return "Bad entry point"
        case .couldNotDisconnect:
            return "Could not disconnect"
        case .badDriver:
            return "Bad driver"
        case .operationNotCompleted:
            return "Operation not completed"
        case .serverBusy:
            return "Server busy"
        case .terminated:
            return "Terminated"
        case .died:
            return "Died"
        case .badHandle:
            return "Bad handle"
        case .unknown:
            return "Unknown plptools error"
        }
    }

}
