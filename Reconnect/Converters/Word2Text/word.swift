/*
    word2text
    word.swift

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


struct PsionWordConstants {

    static let BlockUnitLength: Int       = 6
    static let RecordHeaderLength: Int    = 4
    static let RecordTypes: [String]       = [
        "FILE INFO", "PRINTER CONFIG", "PRINTER DRIVER INFO", "HEADER TEXT", "FOOTER TEXT",
        "STYLE DEFINITION", "EMPHASIS DEFINITION", "BODY TEXT", "STYLE APPLICATION"
    ]
}


struct PsionWord {

    /**
     Convert an individual Word file to plain text.

     - Parameters
     - data:     Data object containing the file bytes.
     May be better to just pass a byte array.
     - filepath: Absolute path of the target Word file.

     - Returns: A ProcessResult containing the text or an error code.
     */
    static func processFile(_ data: ArraySlice<UInt8>) -> ProcessResult {

        var textBytes: [UInt8] = []
        var bodyText: String = ""
        var outerText: [String] = ["", ""]
        var styles: [String:PsionWordStyle] = [:]
        var emphases: [String:PsionWordStyle] = [:]
        var blocks: [PsionWordFormatBlock] = []
        var byteIndex: Int = 40

        // Check minimum file size: enough bytes to at least check the preamble
        if data.count < 16 {
            return ProcessResult(text: "Not a Psion Series 3 Word file", errorCode: .badPsionFileType)
        }

        // Check the data preamble (C String of up to 15 chars plus `NUL`)
        let preamble = String(decoding: data[0..<15], as: UTF8.self)
        if preamble != "PSIONWPDATAFILE" || data.count < 40 {
            // TODO Report actual file type
            return ProcessResult(text: "Not a Psion Series 3 Word file", errorCode: .badPsionFileType)
        }

        // Check for encrypted files: look at file bytes 16 and 17
        // NOTE We can't handle these yet as the decode algorithm remains unknown
        if getWordValue(data[16..<18]) == 256 {
            return ProcessResult(text: "Word file is encrypted", errorCode: .badFileEncrypted)
        }

        // Iterate over the file's bytes to extract the records
        var recordCounter: UInt16 = 0
        while byteIndex < data.count - PsionWordConstants.RecordHeaderLength {
            // Get the 16-bit record type and 16-bit data length
            let recordType = PsionWordRecordType(rawValue: getWordValue(data[byteIndex..<byteIndex + 2])) ?? .unknown
            let recordDataLength: Int = getWordValue(data[byteIndex + 2..<byteIndex + 4])

            // Move index to start of record
            byteIndex += PsionWordConstants.RecordHeaderLength

            // Process the current record
            switch recordType {
                case .fileInfo:
                    // We don't care about this beyond its size
                    if recordDataLength != 10 {
                        return ProcessResult(text: "Bad file info record size (\(recordDataLength) not 10 bytes", errorCode: .badRecordLengthFileInfo)
                    }
                case .printerConfig:
                    // We don't care about this beyond its size
                    if recordDataLength != 58 {
                        return ProcessResult(text: "Bad printer config record size (\(recordDataLength) not 58 bytes", errorCode: .badRecordLengthPrinterConfig)
                    }
                case .printerDriver:
                    // We don't care about this
                    break
                case .headerText:
                    fallthrough
                case .footerText:
                    // Index in strings store is 0 for header, 1 for footer
                    let index = recordType.rawValue - PsionWordRecordType.headerText.rawValue
                    outerText[index] = getOuterText(data[byteIndex..<byteIndex + recordDataLength - 1], index == 0)
                case .styleDefinition:
                    // Check the fixed size
                    if recordDataLength != 80 {
                        return ProcessResult(text: "Bad style definition record size (\(recordDataLength) not 80 bytes", errorCode: .badRecordLengthStyleDefinition)
                    }

                    let style = getStyle(data[byteIndex..<byteIndex + 80], true)
                    styles[style.code] = style
                case .emphasisDefinition:
                    // Check the fixed size
                    if recordDataLength != 28 {
                        return ProcessResult(text: "Bad emphasis definition record size (\(recordDataLength) not 80 bytes", errorCode: .badRecordLengthStyleDefinition)
                    }

                    let emphasis = getStyle(data[byteIndex..<byteIndex + 28], false)
                    emphases[emphasis.code] = emphasis
                case .bodyText:
                    textBytes = getBodyText(data[byteIndex..<byteIndex + recordDataLength])
                case .blockInfo:
                    blocks = getStyleBlocks(data[byteIndex..<data.endIndex], textBytes.count)
                case .unknown:
                    return ProcessResult(text: "Bad Word file record type (\(recordType.rawValue) at  \(String(format: "0x%04x", arguments: [byteIndex]))", errorCode: .badRecordType)
            }

            recordCounter |= (1 << recordType.rawValue)
            byteIndex += recordDataLength
        }

        // Check we have at least one of every record
        if recordCounter != 1022 {
            // Processing ended, but without a complete set of records
            return ProcessResult(text: "File did not include required records", errorCode: .badFileMissingRecords)
        }

        // Psion Series 3a character set is IBM CP 850. The closest Swift supports is Windows 1252,
        // but conversion to UTF-8 using this encoding sometimes fails. So we trap this and try to
        // convert using the older NSString mechanism
        bodyText = convertText(textBytes)

        return ProcessResult(text: bodyText, errorCode: .noError)
    }


    /**
     Parse a Psion Word Style or Emphasis record.

     - Parameters
     - data:     A slice of the word file bytes.
     - isStyle: `true` if the record holds a Style; `false` if it is an Emphasis.

     - Returns A PsionWordStyle containing the record's information.
     */
    private static func getStyle(_ data: ArraySlice<UInt8>, _ isStyle: Bool) -> PsionWordStyle {

        var style: PsionWordStyle = PsionWordStyle()

        // Code and name
        // NOTE `String(cstring:...)` is deprecated so we'll eventually need to scan the bytes
        //      for the NUL terminator and turn the rest into a Swift string
        let index = data.startIndex
        style.code = String(bytes: data[index..<index + 2], encoding: .windowsCP1252) ?? ""
        //style.name = String(cString: [UInt8](data[index + 2..<index + 18]))
        style.name = String(decoding: data[index + 2..<index + 18], as: UTF8.self)
        let range: Range<String.Index> = style.name.range(of: "\0")!    // Find the first nul
        style.name = String(style.name[..<range.lowerBound])

        if style.name.isEmpty {
            style.name = "Unknown"
        }

        // NOTE Many of these properties are irrelevant to text or even Markdown output, so
        //      I may remove unneeded properties at a later time. Do not rely on their presence!

        // Type
        style.isStyle = ((data[index + 18] & 0x01) == 0)
        style.isUndeletable = ((data[index + 18] & 0x02) > 0)
        style.isDefault = ((data[index + 18] & 0x04) > 0)

        // Font type and size
        style.fontCode = getWordValue(data[index + 20..<index + 22])
        style.fontSize = getWordValue(data[index + 24..<index + 26])

        // Textual properties
        style.underlined = ((data[index + 22] & 0x01) > 0)
        style.bold = ((data[index + 22] & 0x02) > 0)
        style.italic = ((data[index + 22] & 0x04) > 0)
        style.superScript = ((data[index + 22] & 0x08) > 0)
        style.subScript = ((data[index + 22] & 0x10) > 0)

        // Property inheritance
        style.inheritUnderline = ((data[index + 26] & 0x01) > 0)
        style.inheritBold = ((data[index + 26] & 0x02) > 0)
        style.inheritItalic = ((data[index + 26] & 0x04) > 0)
        style.inheritSuperScript = ((data[index + 26] & 0x08) > 0)
        style.inheritSubScript = ((data[index + 26] & 0x10) > 0)

        // The following properties apply to Styles only so exit if it's an Emphasis
        if !style.isStyle {
            return style
        }

        // Indents
        style.leftIndent = getWordValue(data[index + 28..<index + 30])
        style.rightIndent = getWordValue(data[index + 30..<index + 32])
        style.firstIdent = getWordValue(data[index + 32..<index + 34])

        // Text alignment
        let alignValue: Int = getWordValue(data[index + 34..<index + 36])
        style.alignment = PsionWordAlignment(rawValue: alignValue) ?? .left

        // Spacing values
        style.lineSpacing = getWordValue(data[index + 36..<index + 38])
        style.spaceAbovePara = getWordValue(data[index + 38..<index + 40])
        style.spaceBelowPara = getWordValue(data[index + 40..<index + 42])
        style.spacing.set(data[index + 42])

        // Outline level
        style.outlineLevel = getWordValue(data[index + 44..<index + 46])

        // Tabs
        let tabCount: Int = getWordValue(data[index + 46..<index + 48])
        if tabCount > 0 {
            var tabIndex: Int = index + 48
            for _ in 0..<tabCount {
                style.tabPositions.append(getWordValue(data[tabIndex..<tabIndex + 2]))
                let tabType: Int = getWordValue(data[tabIndex + 2..<tabIndex + 4])
                style.tabTypes.append(PsionWordTabType(rawValue: tabType) ?? .left)
                tabIndex += 4
            }
        }

        return style
    }


    /**
     Read a C string of known length from the word file byte store

     - Parameters
     - data:      A slice of the word file bytes.
     - isHeader:  `true` if the record contains header text, otherwise `false`.

     - Returns The text as a string.
     */
    private static func getOuterText(_ data: ArraySlice<UInt8>, _ isHeader: Bool) -> String {

        var outerText: String = ""
        let rawLength = data.endIndex - data.startIndex + 1
        if rawLength > 1 {
            // There's at least one character in addition to the C String NUL terminator
            outerText = String(decoding: data[..<(data.endIndex)], as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // String is empty (NUL only)?
        outerText = outerText.count > 0 ? outerText : (isHeader ? "No header" : "No footer")

        return outerText
    }


    /**
     Generate a String from the file's text bytes.

     - Parameters
     - textBytes: The bytes from the Psion file.

     - Returns The text as a String
     */
    private static func convertText(_ textBytes: [UInt8]) -> String {

        guard textBytes.count > 0 else { return "" }

        if let text = String(bytes: textBytes, encoding: .windowsCP1252) {
            // Swift String conversion works - return the result
            return text
        } else {
            // Calculate the number of 'bad' characters and their locations
            var count = 0
            var index = 0
            var badChars: [Int: UInt8] = [:]
            for byte in textBytes {
                if byte > 127 {
                    count += 1
                    badChars[index] = byte
                }

                index += 1
            }

            // Now do the secondary conversion
            // NOTE Encoding set this way to mitigate Linux build error
#if os(macOS)
            let encoding: UInt = NSWindowsCP1252StringEncoding
#elseif os(Linux)
            let encoding: UInt = 12
#endif

            // This works even when the String conversion doesn't!
            if let text: NSString = NSString(bytes: textBytes, length: textBytes.count, encoding: encoding) {
                return String(text)
            }
        }

        return ""
    }


    /**
     Read body text known length from the word file byte store.

     - Parameters
     - data: A slice of the word file bytes containing the body text.

     - Returns The text as a byte array.
     */
    private static func getBodyText(_ data: ArraySlice<UInt8>) -> [UInt8] {

        var textBytes: [UInt8] = []
        for i in 0..<(data.endIndex - data.startIndex) {
            // Process Psion's special character values
            let characterByte = data[data.startIndex + i]
            if characterByte > 127 {
                textBytes.append(charSwap(characterByte))
            } else {
                switch characterByte {
                    case 0:
                        // 0 = paragraph separator
                        textBytes.append(0x0A)
                    case 7:
                        // 7 = unbreakable hyphen
                        textBytes.append(0x2D)
                    case 14:
                        // 14 = soft hyphen (displayed only if used to break line)
                        // NOTE This may be problematic: removing a character may invalidate
                        //      the range values provided in the block format records below.
                        continue
                    case 15:
                        // 15 = unbreakable space
                        textBytes.append(0x20)
                    default:
                        textBytes.append(characterByte)
                }
            }
        }

        return textBytes
    }


    /**
     Swap a CP 850 for a CP 1252.

     - Parameters
     - char: A CP 850 integer value.

     - Returns The equivalent 1252 code.
     */
    private static func charSwap(_ char: UInt8) -> UInt8 {

        // £ (r) (c) 1/2 1/4 3/4 Y P S 0 1 2 3 +/- x - o a f |
        let cp850: [UInt8]  = [0x9C, 0xA9, 0xB8, 0xAB, 0xAC, 0xF3, 0xBE, 0xF4, 0xF5, 0xF8, 0xFB, 0xFD, 0xFC, 0xF1, 0x9E, 0xF6, 0xA7, 0xA6, 0x9F, 0xDD]
        let cp1252: [UInt8] = [0xA3, 0xAE, 0xA9, 0xBD, 0xBC, 0xBE, 0xA5, 0xB6, 0xA7, 0xB0, 0xB9, 0xB2, 0xB3, 0xB1, 0xD7, 0xF7, 0xBA, 0xAA, 0x83, 0xA6]

        if let index = cp850.firstIndex(of: char) {
            return cp1252[index]
        }

        // Return a ? in all other cases
        return 0x3F
    }


    /**
     Parse a Psion Word block styling record and extract the formatting blocks.

     - Parameters
     - data:      A slice of the Word file bytes containing the block formatting data.
     - textLength: The number of bytes in the corresponding body text.
     */
    private static func getStyleBlocks(_ data: ArraySlice<UInt8>, _ textLength: Int) -> [PsionWordFormatBlock] {

        var blocks: [PsionWordFormatBlock] = []
        var recordByteCount = 0
        var dataByteCount = 0
        let length = data.endIndex - data.startIndex
        while recordByteCount < length {
            let blockStartByteIndex = data.startIndex + recordByteCount
            let blockLength: Int = getWordValue(data[blockStartByteIndex..<blockStartByteIndex + 2])

            // FROM 0.1.3
            // Try CP1252 encoding; if it fails (as it does on Linux), try Ascii then default to Body Text
            var styleCode: String = String(bytes: data[blockStartByteIndex + 2..<blockStartByteIndex + 4], encoding: .windowsCP1252) ?? ""
            if styleCode == "" {
                styleCode = String(bytes: data[blockStartByteIndex + 2..<blockStartByteIndex + 4], encoding: .ascii) ?? "BT"
            }

            // FROM 0.1.3
            // Try CP1252 encoding; if it fails (as it does on Linux), try Ascii then default to None
            var emphasisCode: String = String(bytes: data[blockStartByteIndex + 4..<blockStartByteIndex + 6], encoding: .windowsCP1252) ?? ""
            if emphasisCode == "" {
                emphasisCode = String(bytes: data[blockStartByteIndex + 4..<blockStartByteIndex + 6], encoding: .ascii) ?? "NN"
            }

            var block: PsionWordFormatBlock = PsionWordFormatBlock()
            block.styleCode = styleCode
            block.emphasisCode = emphasisCode
            block.startIndex = dataByteCount
            block.endIndex = dataByteCount + blockLength - 1
            if block.endIndex > textLength {
                block.endIndex = textLength
            }

            blocks.append(block)

            dataByteCount += blockLength
            recordByteCount += PsionWordConstants.BlockUnitLength

            if dataByteCount >= textLength {
                break
            }
        }

        return blocks
    }


    /**
     Read a 16-bit little endian value from the Word file byte store.

     - Parameters
     - data:  Two-byte slice of the word file bytes.

     - Returns The value as an (unsinged) integer, or -1 on error.
     */
    private static func getWordValue(_ data: ArraySlice<UInt8>) -> Int {

        // Make sure data slice is correctly dimensioned
        if data.isEmpty || data.count == 1 {
            return -1
        }

        return Int(data[data.startIndex]) + (Int(data[data.startIndex + 1]) << 8)
    }


    /**
     Convert plain text to Markdown by parsing the block formatting data in
     conjunction with the document's stored Style and Emphasis data.

     The raw text is a series of paragraphs separated by NEWLINE.
     A block will contain a style AND an emphasis over a range of characters, in sequence.
     Emphasis can be anywhere (ie. character level); styles are paragraph level.
     Initially we will support STANDARD Styles and Emphases. Only a subset of each require
     tagging with Markdown (eg. `HA` -> `#`, `BB` -> `**`.

     - Note This all assumes that the doc only contains standard styles, but what if it has, say,
     a headline set to bold text, ie. a custom style? A bold headline in Markdown would be
     `# **headline**, but this would not comprise separate blocks. So we need to set the `#`
     on the paragraph start and (separately) the `**` at the start and end of the actual text.

     - Parameters
     - rawText:  The basic Ascii text.
     - blocks:   The block formatting data extracted from the document.
     - styles:   The styles extracted from the document.
     - emphases: The emphases extracted from the document.

     - Returns: A Markdown-formatted version of the base text.
     */
    private static func convertToMarkdown(_ rawText: [UInt8], _ blocks: [PsionWordFormatBlock], _ styles: [String:PsionWordStyle], _ emphases: [String:PsionWordStyle]) -> String {

        var markdown: String = ""
        var paraStyleSet: Bool = false
        var textEndTag: String = ""

        // Blocks are in stored in sequence, so we just need to iterate over them
        for block in blocks {
            var tag: String = ""
            var isEmphasisTag: Bool = false

            if !paraStyleSet {
                // Starting a new para, so the Style should not change
                paraStyleSet = true

                // Look for
                switch block.styleCode {
                    case "HA":
                        tag = "# "
                    case "HB":
                        tag = "### "
                    case "BL":
                        // Bullet list
                        tag = "* "
                    default:
                        if block.styleCode != "BT" {
                            // NOTE User-defined style may have any name
                            if let style: PsionWordStyle = styles[block.styleCode] {
                                // Use font size
                                var size = (Int(0.05 * Double(style.fontSize)) >> 1)
                                if size > 10 {
                                    size = 10
                                }

                                // Ignore sizes below 7 (13pt)
                                if size > 6 {
                                    size = 10 - size + 1
                                    tag = String(repeating: "#", count: size)
                                    tag += " "
                                }

                                if style.bold {
                                    tag += "**"
                                    textEndTag = "**"
                                } else if style.italic {
                                    textEndTag = "*"
                                }
                            }
                        }
                }
            }

            // Look for in-paragraph tags.
            // NOTE BB (Bold) and II (Italic) are the only ones relevant to Markdown
            if tag == "" {
                switch block.emphasisCode {
                    case "BB":
                        tag = "**"
                        isEmphasisTag = true
                    case "II":
                        tag = "*"
                        isEmphasisTag = true
                    default:
                        tag = ""
                }
            }

            // Add the tagged text to the string store. We only duplicate the tag at the end
            // of the block if it is a character-level tag, ie. an Emphasis
            var addition = convertText([UInt8](rawText[block.startIndex...block.endIndex])) // String(bytes: rawText[block.startIndex...block.endIndex], encoding: .windowsCP1252) {
            // Check if we've come to the end of a paragraph - but not empty ones
            if addition.hasSuffix("\n") && addition.count > 1 {
                // Remove the NEWLINE
                _ = addition.removeLast()
                markdown += (tag + addition + (isEmphasisTag ? tag : ""))

                if !textEndTag.isEmpty {
                    markdown += textEndTag
                    textEndTag = ""
                }

                // Add the NEWLINE back, after the tgitsyncags
                markdown += "\n"

                // Reset the paragraph found flag
                paraStyleSet = false
            } else if addition.hasSuffix("\n") && addition.count ==  1 {
                paraStyleSet = false
                markdown += "\n"
            } else {
                // Just add the tags
                markdown += (tag + addition + (isEmphasisTag ? tag : ""))
            }
        }

        return markdown
    }


    /**
     Determine the longest length of two strings
     */
    private static func greater(_ a: Substring, _ b: Substring) -> String {

        if a.count > b.count {
            return String(a)
        }

        return String(b)
    }


    /**
     Output raw bytes as hex values.

     Required for debugging ONLY.
     */
    private static func debugPrintBytes(_ data: ArraySlice<UInt8>) {

        var s = ""
        for byte in data {
            s += String(format: "%02X", byte)
        }

        print(s)
    }
}
