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

public struct Localization {

    public let language: String
    public let text: String

}

extension Locale {

    public static func selectLanguage(_ candidates: any Collection<String>) throws -> String {
        let candidates = Set(candidates)
        for language in preferredLanguages {
            let language = language.replacingOccurrences(of: "-", with: "_")  // Convert to the OpoLua language identifier format.
            if candidates.contains(language) {
                return language
            }
        }
        guard let language = candidates.sorted().first else {
            throw ReconnectError.invalidLocalization
        }
        return language
    }

    public static func localize(_ localizations: [String: String]) throws -> Localization {
        let language = try selectLanguage(localizations.keys)
        return Localization(language: language, text: localizations[language]!)
    }

}
