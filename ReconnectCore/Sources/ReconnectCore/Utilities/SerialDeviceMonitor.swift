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

import Foundation
import IOKit
import IOKit.serial

public protocol SerialDeviceMonitorDelegate: NSObject {

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didAddDevice device: String)
    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didRemoveDevice device: String)

}

public class SerialDeviceMonitor {

    public weak var delegate: SerialDeviceMonitorDelegate?

    public init() {
        
    }

    public func start() {
        let matchingDict = IOServiceMatching(kIOSerialBSDServiceValue)
        var notifyPort: IONotificationPortRef?
        var addedIterator: io_iterator_t = 0
        var removedIterator: io_iterator_t = 0

        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        let runLoopSource = IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

        let context = Unmanaged.passRetained(self).toOpaque()

        // TODO: Store this notification and remove it in the future.
        IOServiceAddMatchingNotification(
            notifyPort!,
            kIOMatchedNotification,
            matchingDict,
            { (context, iterator) in
                guard let context else {
                    return
                }
                let monitor = Unmanaged<SerialDeviceMonitor>.fromOpaque(context).takeUnretainedValue()
                while case let service = IOIteratorNext(iterator), service != 0 {
                    monitor.deviceAdded(service: service)
                }
            },
            context,
            &addedIterator
        )

        // TODO: Store this notification and remove it in the future.
        IOServiceAddMatchingNotification(
            notifyPort!,
            kIOTerminatedNotification,
            matchingDict,
            { (context, iterator) in
                guard let context else {
                    return
                }
                let monitor = Unmanaged<SerialDeviceMonitor>.fromOpaque(context).takeUnretainedValue()
                while case let service = IOIteratorNext(iterator), service != 0 {
                    monitor.deviceRemoved(service: service)
                }
            },
            context,
            &removedIterator
        )

        // Check the notification iterators for their initial state. We do this for both iterators as it ensures we have
        // the correct initial state and is required to arm the notifications.
        // https://developer.apple.com/documentation/iokit/1514362-ioserviceaddmatchingnotification

        // Handle existing removals.
        while case let service = IOIteratorNext(removedIterator), service != 0 {
            deviceRemoved(service: service)
        }

        // Handle existing additions.
        while case let service = IOIteratorNext(addedIterator), service != 0 {
            deviceAdded(service: service)
        }

    }

    func stop() {
        // TODO: Figure out where this notification is owned and how we call ack to an existing object.
    }

    func deviceAdded(service: io_object_t) {
        dispatchPrecondition(condition: .onQueue(.main))
        defer {
            IOObjectRelease(service)
        }
        if let deviceName = IORegistryEntryCreateCFProperty(service,
                                                            kIOCalloutDeviceKey as CFString,
                                                            kCFAllocatorDefault, 0)?.takeUnretainedValue() as? String {
            delegate?.serialDeviceMonitor(serialDeviceMonitor: self, didAddDevice: deviceName)
        }
    }

    func deviceRemoved(service: io_object_t) {
        dispatchPrecondition(condition: .onQueue(.main))
        defer {
            IOObjectRelease(service)
        }
        if let deviceName = IORegistryEntryCreateCFProperty(service,
                                                            kIOCalloutDeviceKey as CFString,
                                                            kCFAllocatorDefault, 0)?.takeUnretainedValue() as? String {
            delegate?.serialDeviceMonitor(serialDeviceMonitor: self, didRemoveDevice: deviceName)
        }
    }

}
