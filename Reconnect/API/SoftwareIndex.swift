// Copyright (c) 2024-2026 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

extension URL {
    static let softwareIndexAPIV1 = URL(string: "https://software.psion.community/api/v1")!
    static let softwareIndexFilesURL = URL(string: "https://software.psion.community/files")!

}

struct SoftwareIndex {

    struct Collection: Codable, Identifiable, Hashable {

        var id: String {
            return identifier
        }

        let identifier: String
        let items: [Release]

    }

    struct Image: Codable, Hashable {

        let width: Int
        let height: Int
        let path: String

    }

    enum Kind: String, Codable, Sendable {
        case installer
        case standalone
    }

    struct Program: Codable, Identifiable, Hashable {

        let id: String
        let name: String
        let icon: Image?
        let versions: [Version]
        let subtitle: String?
        let description: String?
        let tags: [String]
        var screenshots: [Image]?

        var iconURL: URL? {
            guard let icon else {
                return nil
            }
            return .softwareIndexAPIV1
                .appendingPathComponent(icon.path)
        }

    }

    struct ReferenceItem: Codable, Hashable {

        let name: String
        let url: URL?

    }

    struct Release: Codable, Hashable, Sendable {

        public var uniqueId: String {
            return id + referenceString
        }

        public let id: String
        public let uid: String?
        public let kind: Kind
        public let name: String
        let icon: Image?
        let filename: String
        let size: Int
        let sha256: String
        let reference: [ReferenceItem]
        public let tags: [String]

        var iconURL: URL? {
            guard let icon else {
                return nil
            }
            return .softwareIndexAPIV1
                .appendingPathComponent(icon.path)
        }

        var referenceString: String {
            return reference
                .map { $0.name }
                .joined(separator: " - ")
        }

        var downloadURL: URL {
            return .softwareIndexFilesURL
                .appendingPathComponent(sha256)
        }

    }

    struct Version: Codable, Identifiable, Hashable {

        var id: String {
            return version
        }

        let version: String
        let variants: [Collection]

    }

}
