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

import Interact

struct DeviceEditView: View {

    @Environment(\.dismiss) private var dismiss

    var deviceModel: DeviceModel

    @State var name: String
    @State var isSaving: Bool = false
    @State var error: Error? = nil

    init(deviceModel: DeviceModel) {
        self.deviceModel = deviceModel
        _name = State(initialValue: deviceModel.name)
    }

    var body: some View {
        WizardPage("Edit Device") {
            Form {
                TextField("Name", text: $name)
            }
            .padding()
            .frame(maxWidth: WizardLayoutMetrics.maximumContentWidth)
        } actions: {
            Button("Cancel", role: .destructive) {
                dismiss()
            }
            .disabled(isSaving)
            Button("OK") {
                deviceModel.setName(name) { error in
                    if let error = error {
                        self.error = error
                    } else {
                        dismiss()
                    }
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(name == deviceModel.name || isSaving)
        }
        .presents($error)
    }

}
