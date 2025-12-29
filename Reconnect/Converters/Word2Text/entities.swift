/*
    word2text
    entities.swift

    Copyright © 2025 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

import Foundation


/*
    Structure to hold the outcome of a single file processing operation.
 
    The `text` property will either be the file's textual content or an error message.
    
    The `errorCode` value will be zero on a successful process, or an error code if processing
    failed. This can be used as an exit code and to determine what kind of content `text`
    contains.
*/
struct ProcessResult {
    var text: String
    var errorCode: ProcessError
}


/*
    Structure to hold a Style or Emphasis record.
 
    Not all of the fields are used by each type
*/
struct PsionWordStyle {
    var code: String = ""
    var name: String = ""
    var isStyle: Bool = true                // `true` for a style, `false` for an emphasis
    var isUndeletable: Bool = false
    var isDefault: Bool = false
    var fontCode: Int = 0
    var underlined: Bool = false
    var bold: Bool = false
    var italic: Bool = false
    var superScript: Bool = false           // Emphasis only
    var subScript: Bool = false             // Emphasis only
    var fontSize: Int = 10                  // Multiple of 0.05
    var inheritUnderline: Bool  = false
    var inheritBold: Bool = false
    var inheritItalic: Bool = false
    var inheritSuperScript: Bool = false
    var inheritSubScript: Bool = false
    var leftIndent: Int = 0                 // This and all remaining members
    var rightIndent: Int = 0                // are Style only
    var firstIdent: Int = 0
    var alignment: PsionWordAlignment = .left
    var lineSpacing: Int = 0
    var spaceAbovePara: Int = 0
    var spaceBelowPara: Int = 0
    var spacing: PsionWordSpacing = .keepTogether
    var outlineLevel: Int = 0
    var tabPositions: [Int] = []
    var tabTypes: [PsionWordTabType] = []
}


/*
    Text section formattting information.
*/
struct PsionWordFormatBlock {
    var startIndex: Int = 0
    var endIndex: Int = 0
    var styleCode: String = "BT"
    var emphasisCode: String = "NN"
}


/*
    Text alignment options.
    NOTE We require raw values for these
*/
enum PsionWordAlignment: Int {
    case left = 0
    case right = 1
    case centered = 2
    case justified = 3
    case unknown = 99
}


/*
    Paragraph spacing options
*/
enum PsionWordSpacing {
    case keepWithNext
    case keepTogether
    case newPage
    case noSpacing
}

extension PsionWordSpacing {
    mutating func set(_ value: UInt8) {
        if value & 0x01 > 0 {
            self = .keepWithNext
        } else if value & 0x02 > 0 {
            self = .keepTogether
        } else if value & 0x04 > 0 {
            self = .newPage
        } else {
            self = .noSpacing
        }
    }
}


/*
    Tabulation options
*/
enum PsionWordTabType: Int {
    case left = 0
    case right = 1
    case centered = 2
}


/*
    Word file processing error codes.
    NOTE We require raw values for these, for output as stderr codes.
*/
enum ProcessError: Int {
    case noError = 0
    case badFile = 1
    case badPsionFileType = 2
    case badFileEncrypted = 3
    case badRecordLengthFileInfo = 4
    case badRecordLengthPrinterConfig = 5
    case badRecordLengthStyleDefinition = 6
    case badRecordLengthEmphahsisDefinition = 7
    case badRecordType = 8
    case badFileMissingRecords = 9
}


/*
    Word file record types.
    NOTE We require raw values for these, to match to record type bytes.
*/
enum PsionWordRecordType: Int {
    case fileInfo = 1
    case printerConfig = 2
    case printerDriver = 3
    case headerText = 4
    case footerText = 5
    case styleDefinition = 6
    case emphasisDefinition = 7
    case bodyText = 8
    case blockInfo = 9
    case unknown = 99
}
