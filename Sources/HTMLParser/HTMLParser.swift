//
//  MIT License
//
//  Created by hengyu on 2021/1/10.
//  Copyright © 2021-2023 hengyu. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import CoreFoundation
import Foundation
import libxml2

extension String.Encoding {
    var ianaCharSetName: String? {
        switch self {
        case .ascii: return "us-ascii"
        case .iso2022JP: return "iso-2022-jp"
        case .isoLatin1: return "iso-8859-1"
        case .isoLatin2: return "iso-8859-2"
        case .japaneseEUC: return "euc-jp"
        case .macOSRoman: return "macintosh"
        case .nextstep: return "x-nextstep"
        case .nonLossyASCII: return nil
        case .shiftJIS: return "cp932"
        case .symbol: return "x-mac-symbol"
        case .unicode: return "utf-16"
        case .utf16: return "utf-16"
        case .utf16BigEndian: return "utf-16be"
        case .utf32: return "utf-32"
        case .utf32BigEndian: return "utf-32be"
        case .utf32LittleEndian: return "utf-32le"
        case .utf8: return "utf-8"
        case .windowsCP1250: return "windows-1250"
        case .windowsCP1251: return "windows-1251"
        case .windowsCP1252: return "windows-1252"
        case .windowsCP1253: return "windows-1253"
        case .windowsCP1254: return "windows-1254"
        case .init(cEncoding: .UTF7): return CFStringEncodings.UTF7.ianaCharsetName
        case .init(cEncoding: .GB_18030_2000): return CFStringEncodings.GB_18030_2000.ianaCharsetName
        case .init(cEncoding: .GB_2312_80): return "gb_2312-80"
        case .init(cEncoding: .GBK_95): return "gbk"
        default: return nil
        }
    }

    private init(cEncoding: CFStringEncodings) {
        let rawValue = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cEncoding.rawValue))
        self.init(rawValue: rawValue)
    }
}

extension CFStringEncodings {

    var ianaCharsetName: String {
        CFStringConvertEncodingToIANACharSetName(CFStringEncoding(rawValue)) as String
    }
}

public final class HTMLParser: Sendable {

    private let docPtr: htmlDocPtr

    private var document: HTMLNode? {
        if let nodePtr = xmlDocGetRootElement(docPtr) {
            return HTMLNode(nodePtr: nodePtr)
        } else {
            return nil
        }
    }

    public var htmlNode: HTMLNode? {
        document?.findChild(withTag: "html")
    }

    public var headNode: HTMLNode? {
        document?.findChild(withTag: "head")
    }

    public var bodyNode: HTMLNode? {
        document?.findChild(withTag: "body")
    }

    public convenience init?(
        data: Data,
        encoding: String.Encoding,
        option: UInt32 = HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NOERROR.rawValue | HTML_PARSE_NOWARNING.rawValue
    ) {
        guard let html = String(data: data, encoding: encoding) else { return nil }
        self.init(html: html, encoding: encoding, option: option)
    }

    public init?(
        html: String,
        encoding: String.Encoding,
        option: UInt32 = HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NOERROR.rawValue | HTML_PARSE_NOWARNING.rawValue
    ) {
        guard
            html.lengthOfBytes(using: encoding) > 0,
            let charsetName = encoding.ianaCharSetName,
            let cur = html.cString(using: encoding)
        else { return nil }

        let docPtr = cur.withUnsafeBytes {
            htmlReadDoc(
                $0.bindMemory(to: xmlChar.self).baseAddress!,
                nil,
                charsetName,
                CInt(option)
            )
        }

        if let docPtr {
            self.docPtr = docPtr
        } else {
            return nil
        }
    }

    deinit {
        xmlFreeDoc(docPtr)
    }
}
