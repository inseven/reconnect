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

struct MachineDetailsGroup: View {

    var body: some View {
        DetailsGroup {
            VStack(alignment: .leading) {
                LabeledContent("Type:", value: "Series 7")
                LabeledContent("Software Version:", value: "1.05(254)")
                LabeledContent("Language:", value: "English (UK)")
                LabeledContent("Unique Id:", value: "0908-0001-006F-1FBD")
            }
            .labeledContentStyle(.details)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Machine")
        }
    }

}
