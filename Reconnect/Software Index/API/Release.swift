// Copyright (c) 2024-2025 Jason Morley
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

public struct Release: Codable, Identifiable, Hashable {

    public var id: String {
        return uid + referenceString
    }

    public let uid: String
    public let kind: Kind
    public let name: String
    let icon: SoftwareIndexImage?
    let filename: String
    let size: Int
    let sha256: String
    let reference: [ReferenceItem]
    public let tags: [String]

    var iconURL: URL? {
        guard let icon else {
            return nil
        }
        return URL.softwareIndexAPIV1.appendingPathComponent(icon.path)
    }

    var referenceString: String {
        return reference
            .map { $0.name }
            .joined(separator: " - ")
    }

    var downloadURL: URL {
        return URL(string: "https://software.psion.info/files/\(sha256)")!
    }

}
