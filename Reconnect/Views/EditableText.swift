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

import SwiftUI

// This exists as a fairly gnarly workaround to turn SwiftUI's continuous table view text field editing back into
// something that looks vaguely modal. It's possible we'd also get this for free by writing using an NSTextField
// directly, but that's for another day; until then, debouncing edits will have to be sufficient.
struct EditableText: View {

    @StateObject var model: EditableTextModel

    init(initialValue: String, completion: @escaping (String) -> Void) {
        _model = StateObject(wrappedValue: EditableTextModel(initialValue: initialValue, completion: completion))
    }

    var body: some View {
        TextField("", text: $model.text)
            .runs(model)
    }

}
