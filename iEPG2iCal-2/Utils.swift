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

    class func parseContentType(let string: String) -> (NSString?, NSStringEncoding) {
        var contentType: NSString?
        var encoding:    NSStringEncoding = NSASCIIStringEncoding

        let components: NSArray = string.componentsSeparatedByString(";")
        for var i = 0; i < components.count; i++ {
            let s: NSString = components.objectAtIndex(i) as NSString

            if i == 0 {
                contentType = s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            } else {
                let (name, value) = Utils.splitStringIntoKeyAndValue(s, delimiter: "=")

                switch name {
                case let name where name.isCaseInsensitiveLike("charset"):
                    encoding = Utils.determinCharsetEncoding(value)

                default:
                    break
                }
            }
        }
        
        return (contentType, encoding)
    }
    
    class func splitStringIntoKeyAndValue(let string: NSString, let delimiter: String) -> (NSString, NSString) {
        let range: NSRange  = string.rangeOfString(delimiter)

        let key:   NSString = string.substringToIndex(range.location).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let value: NSString = string.substringFromIndex(range.location + range.length).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        return (key, value)
    }
    
}
