//
//  Util.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 9/4/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Cocoa

class Utils {

    class func determinCharsetEncoding(let string: NSString) -> (NSStringEncoding) {
        var encoding: NSStringEncoding

        switch string {
        case let value where value.isCaseInsensitiveLike("UTF-8"):
            encoding = NSUTF8StringEncoding

        case let value where value.isCaseInsensitiveLike("Shift_JIS"):
            encoding = NSShiftJISStringEncoding

        default:
            encoding = NSASCIIStringEncoding
        }

        return encoding
    }

    class func parseContentType(let string: String) -> (String?, NSStringEncoding) {
        var contentType: String?
        var encoding:    NSStringEncoding = NSASCIIStringEncoding

        let components: [String] = string.componentsSeparatedByString(";")
        for var i = 0; i < components.count; i++ {
            let s: String = components[i]

            if i == 0 {
                contentType = s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            } else {
                let (name, value) = Utils.splitStringIntoKeyAndValue(s, delimiter: "=")

                if (name as NSString).lowercaseString == "charset" {
                    encoding = Utils.determinCharsetEncoding(value)
                }
            }
        }

        return (contentType, encoding)
    }

    class func splitStringIntoKeyAndValue(let string: String, let delimiter: String) -> (String, String) {
        var key:   String = ""
        var value: String = ""

        let range: Range? = string.rangeOfString(delimiter)
        if range != nil {
            key = string.substringToIndex(range!.startIndex).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            value = string.substringFromIndex(range!.endIndex).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
        
        return (key, value)
    }
    
}
