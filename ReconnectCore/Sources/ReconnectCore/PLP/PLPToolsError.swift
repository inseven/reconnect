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
        return LocalizedEpoc32ErrorCode(rawValue)
    }

}
