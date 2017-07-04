//
//  Util.swift
//  iEPG2iCal
//
//  Created by Wataru SUZUKI on 9/4/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation

class Utils {

    class func determinCharsetEncoding(_ string: String) -> (String.Encoding) {
        var encoding: String.Encoding

        switch string {
        case let value where value.lowercased() == "utf-8":
            encoding = String.Encoding.utf8

        case let value where value.lowercased() == "shift_jis":
            encoding = String.Encoding.shiftJIS

        default:
            encoding = String.Encoding.ascii
        }

        return encoding
    }

    class func parseContentType(_ string: String) -> (String?, String.Encoding) {
        var contentType: String?
        var encoding:    String.Encoding = String.Encoding.ascii

        let components: [String] = string.components(separatedBy: ";")
        for i in 0 ..< components.count {
            let s: String = components[i]

            if i == 0 {
                contentType = s.trimmingCharacters(in: CharacterSet.whitespaces)
            } else {
                let (name, value) = Utils.splitStringIntoKeyAndValue(s, delimiter: "=")

                if name.lowercased() == "charset" {
                    encoding = Utils.determinCharsetEncoding(value)
                }
            }
        }

        return (contentType, encoding)
    }

    class func splitStringIntoKeyAndValue(_ string: String, delimiter: String) -> (String, String) {
        var key:   String = ""
        var value: String = ""

        let range: Range? = string.range(of: delimiter)
        if range != nil {
            key = string.substring(to: range!.lowerBound).trimmingCharacters(in: CharacterSet.whitespaces)
            value = string.substring(from: range!.upperBound).trimmingCharacters(in: CharacterSet.whitespaces)
        }

        return (key, value)
    }
    
}
