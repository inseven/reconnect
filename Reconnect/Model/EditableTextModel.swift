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

import Combine
import SwiftUI

import Interact

class EditableTextModel: ObservableObject, Runnable {

    @Published var text: String = ""

    private let initialValue: String
    private let completion: (String) -> Void

    private var cancellables: Set<AnyCancellable> = []

    init(initialValue: String, completion: @escaping (String) -> Void) {
        self.initialValue = initialValue
        self.completion = completion
        self.text = initialValue
    }

    func start() {
        $text
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .sink { text in
                dispatchPrecondition(condition: .onQueue(.main))
                guard text != self.initialValue else {
                    return
                }
                self.completion(text)
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
    }

}
