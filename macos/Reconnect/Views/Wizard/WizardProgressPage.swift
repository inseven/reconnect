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
import ReconnectCore

struct WizardProgressPage: View {

    private let animation: String
    private let progress: Progress
    private let cancellationToken: CancellationToken

    init(_ animation: String, progress: Progress, cancellationToken: CancellationToken) {
        self.animation = animation
        self.progress = progress
        self.cancellationToken = cancellationToken
    }

    var body: some View {
        WizardPage {
            ProgressAnimation(animation)
            ProgressView(progress)
                .lineLimit(1)
                .truncationMode(.middle)
        } actions: {
            Button("Cancel", role: .destructive) {
                cancellationToken.cancel()
            }
            .disabled(cancellationToken.isCancelled)
            Button("Continue") {}
                .keyboardShortcut(.defaultAction)
                .disabled(true)
        }
        .wizardPageStyle(.narrow)
    }

}
