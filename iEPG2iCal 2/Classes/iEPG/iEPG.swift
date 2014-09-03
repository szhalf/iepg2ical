//
//  iEPG.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Cocoa

class iEPG {
    let CRLF: NSData = NSData(bytes: "\r\n".UTF8String, length: 2)

    var programInformations: NSMutableArray
    var sourceData:          NSData

    init() {
        self.programInformations = NSMutableArray()
        self.sourceData          = NSData()
    }

    convenience init(path: NSString) {
        self.init()

        self.sourceData = NSData(contentsOfFile: path)

        self.parse()
    }

    func parse() {
        // searching content mime type and boundary
        var contentType: NSString?
        var encoding:    NSStringEncoding = NSASCIIStringEncoding
        var boundary:    NSString?

        var cursor: Int = 0
        while cursor < self.sourceData.length {
            var range1: NSRange = self.sourceData.rangeOfData(CRLF, options: NSDataSearchOptions(0), range: NSMakeRange(cursor, self.sourceData.length - cursor))

            if range1.location == NSNotFound {
                break
            }

            if cursor == range1.location {
                cursor = range1.location + CRLF.length
                break
            }

            var lineData: NSData   = self.sourceData.subdataWithRange(NSMakeRange(cursor, range1.location - cursor))
            var line:     NSString = NSString(data: lineData, encoding: NSASCIIStringEncoding)
            var range2:   NSRange  = line.rangeOfString(":")

            if range2.location != NSNotFound {
                var name:  NSString = line.substringToIndex(range2.location)
                var value: NSString = line.substringFromIndex(range2.location + range2.length)

                switch name {
                case let name where name.isCaseInsensitiveLike("content-type"):
                    (contentType, encoding) = self.parseContentType(value)
                case let name where name.isCaseInsensitiveLike("boundary"):
                    boundary = value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                default:
                    continue
                }
            }
            cursor = range1.location + CRLF.length
        }

        if contentType!.isCaseInsensitiveLike("application/x-tv-program-info") {
            self.programInformations.addObject(TVProgramInfo(data: self.sourceData))
        } else if contentType!.isCaseInsensitiveLike("application/x-multi-tv-program-info") {
            if boundary == nil {
                return
            }

            var boundaryData: NSMutableData = NSMutableData.dataWithData(CRLF)
            boundaryData.appendData(boundary!.dataUsingEncoding(encoding)!)

            var terminatorData: NSMutableData = NSMutableData(data: boundaryData)
            terminatorData.appendData(NSString(string: "--").dataUsingEncoding(encoding)!)

            while cursor < self.sourceData.length {
                var range:              NSRange = NSMakeRange(cursor, self.sourceData.length - cursor)
                var boundaryPosition:   NSRange = self.sourceData.rangeOfData(boundaryData, options:NSDataSearchOptions(0), range:range)
                var terminatorPosition: NSRange = self.sourceData.rangeOfData(terminatorData, options:NSDataSearchOptions(0), range:range)

                if boundaryPosition.location == NSNotFound {
                    break
                }
                if cursor == boundaryPosition.location {
                    cursor = boundaryPosition.location + boundaryPosition.length + CRLF.length
                    continue
                }

                var data: NSData = self.sourceData.subdataWithRange(NSMakeRange(cursor, boundaryPosition.location - cursor))

                self.programInformations.addObject(TVProgramInfo(data: data))

                if boundaryPosition.location == terminatorPosition.location {
                    break
                }
                cursor = boundaryPosition.location + boundaryPosition.length + CRLF.length
            }
        }
    }

    func parseContentType(value: String) -> (NSString?, NSStringEncoding) {
        var contentType: NSString?
        var encoding:    NSStringEncoding = NSASCIIStringEncoding

        let components: NSArray = value.componentsSeparatedByString(";")
        for var i = 0; i < components.count; i++ {
            let s: NSString = components.objectAtIndex(i) as NSString

            if i == 0 {
                contentType = s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            } else {
                let (name, value) = self.splitStringIntoKeyAndValue(s, delimiter: "=")

                switch name {
                case let name where name.isCaseInsensitiveLike("charset"):
                    encoding = self.determinCharsetEncoding(value)
                default:
                    continue
                }
            }
        }

        return (contentType, encoding)
    }

    func splitStringIntoKeyAndValue(string: NSString, delimiter: String) -> (NSString, NSString) {
        var range: NSRange  = string.rangeOfString(delimiter)

        var key:   NSString = string.substringToIndex(range.location)
        var value: NSString = string.substringFromIndex(range.location + range.length)

        key   = key.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        value = value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        return (key, value)
    }

    func determinCharsetEncoding(string: NSString) -> (NSStringEncoding) {
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
}

