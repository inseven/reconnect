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

import Interact

import ReconnectCore

@MainActor @Observable
class ApplicationModel: NSObject {

    struct SerialDevice: Identifiable {

        var id: String {
            return path
        }

        var path: String
        var available: Bool
        var enabled: Binding<Bool>
    }

    enum SettingsKey: String {
        case selectedDevices
    }

    var isConnected: Bool = false

    var devices: [SerialDevice] {
        return connectedDevices.union(selectedDevices)
            .map { device in
                let binding: Binding<Bool> = Binding {
                    return self.selectedDevices.contains(device)
                } set: { newValue in
                    if newValue {
                        self.selectedDevices.insert(device)
                    } else {
                        self.selectedDevices.remove(device)
                    }
                }
                return SerialDevice(path: device,
                                    available: connectedDevices.contains(device),
                                    enabled: binding)
            }
            .sorted { device1, device2 in
                return device1.path.localizedStandardCompare(device2.path) == .orderedAscending
            }
    }

    private var selectedDevices: Set<String> {
        didSet {
            keyedDefaults.set(Array(selectedDevices), forKey: .selectedDevices)
            update()
        }
    }

    private var connectedDevices: Set<String> = [] {
        didSet {
            update()
        }
    }

    private let keyedDefaults = KeyedDefaults<SettingsKey>()
    private let server: Server = Server()
    private let serialDeviceMonitor = SerialDeviceMonitor()

    override init() {
        selectedDevices = Set(keyedDefaults.object(forKey: .selectedDevices) as? Array<String> ?? [])
        super.init()
        server.delegate = self
        serialDeviceMonitor.delegate = self
        start()
    }

    func start() {
        server.start()
        serialDeviceMonitor.start()
    }

    @MainActor func quit() {
        NSApplication.shared.terminate(nil)
    }

    func update() {
        server.setDevices(selectedDevices.intersection(connectedDevices).sorted())
    }

}

extension ApplicationModel: ServerDelegate {

    func server(server: Server, didChangeConnectionState isConnected: Bool) {
        self.isConnected = isConnected
    }

}

extension ApplicationModel: SerialDeviceMonitorDelegate {

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didAddDevice device: String) {
        connectedDevices.insert(device)

    }

    func serialDeviceMonitor(serialDeviceMonitor: SerialDeviceMonitor, didRemoveDevice device: String) {
        connectedDevices.remove(device)
    }

}
