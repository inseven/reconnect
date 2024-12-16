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

import Interact
import Licensable
import OpoLua

fileprivate let plptoolsLicense = License(id: "https://github.com/rrthomas/plptools",
                                          name: "plptools",
                                          author: "plptools Authors",
                                          text: String(contentsOfResource: "plptools-license"),
                                          attributes: [
                                              .url(URL(string: "https://github.com/rrthomas/plptools")!, title: "GitHub"),
                                          ],
                                          licenses: [])

fileprivate let sparkleLicense = License(id: "https://github.com/sparkle-project/Sparkle",
                                         name: "Sparkle",
                                         author: "Sparkle Project",
                                         text: String(contentsOfResource: "sparkle-license"),
                                         attributes: [
                                            .url(URL(string: "https://github.com/sparkle-project/Sparkle")!, title: "GitHub"),
                                            .url(URL(string: "https://sparkle-project.org")!, title: "Website"),
                                         ],
                                         licenses: [])

fileprivate let reconnectLicense = License(id: "https://github.com/inseven/thoughts",
                                           name: "Reconnect",
                                           author: "Jason Morley",
                                           text: String(contentsOfResource: "reconnect-license"),
                                           attributes: [
                                               .url(URL(string: "https://github.com/inseven/reconnect")!, title: "GitHub"),
                                           ],
                                           licenses: [
                                               .interact,
                                               .licensable,
                                               .opolua,
                                               plptoolsLicense,
                                               sparkleLicense,
                                           ])

extension Licensable where Self == License {

    public static var reconnect: License { reconnectLicense }

}
