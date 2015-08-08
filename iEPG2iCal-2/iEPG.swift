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

    var programInformations: [TVProgramInfo]
    var sourceData:          NSData

    init() {
        self.programInformations = []
        self.sourceData          = NSData()
    }

    convenience init(let path: String) {
        self.init()

        self.sourceData = NSData(contentsOfFile: path)!

        self.parse()
    }

    func parse() {
        // searching content mime type and boundary
        var contentType: String?
        var encoding:    NSStringEncoding = NSASCIIStringEncoding
        var boundary:    String?

        var cursor: Int = 0
        while cursor < self.sourceData.length {
            let range1: NSRange = self.sourceData.rangeOfData(CRLF, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(cursor, self.sourceData.length - cursor))

            if range1.location == NSNotFound {
                break
            }

            if cursor == range1.location {
                cursor = range1.location + CRLF.length
                break
            }

            let lineData: NSData = self.sourceData.subdataWithRange(NSMakeRange(cursor, range1.location - cursor))
            let line:     String = NSString(data: lineData, encoding: NSASCIIStringEncoding)! as String

            let (name, value) = Utils.splitStringIntoKeyAndValue(line, delimiter: ":")

            switch name.lowercaseString {
            case "content-type":
                (contentType, encoding) = Utils.parseContentType(value as String)

            case "boundary":
                boundary = value

            default:
                break
            }

            cursor = range1.location + CRLF.length
        }

        if (contentType as NSString!).isCaseInsensitiveLike("application/x-tv-program-info") {
            self.programInformations.append(TVProgramInfo(data: self.sourceData))
        } else if (contentType as NSString!).isCaseInsensitiveLike("application/x-multi-tv-program-info") {
            if boundary == nil {
                return
            }

            let boundaryData: NSMutableData = NSMutableData(data: CRLF)
            boundaryData.appendData(boundary!.dataUsingEncoding(encoding)!)

            let terminatorData: NSMutableData = NSMutableData(data: boundaryData)
            terminatorData.appendData(NSString(string: "--").dataUsingEncoding(encoding)!)

            while cursor < self.sourceData.length {
                let range:              NSRange = NSMakeRange(cursor, self.sourceData.length - cursor)
                let boundaryPosition:   NSRange = self.sourceData.rangeOfData(boundaryData, options:NSDataSearchOptions(rawValue: 0), range:range)
                let terminatorPosition: NSRange = self.sourceData.rangeOfData(terminatorData, options:NSDataSearchOptions(rawValue: 0), range:range)

                if boundaryPosition.location == NSNotFound {
                    break
                }
                if cursor == boundaryPosition.location {
                    cursor = boundaryPosition.location + boundaryPosition.length + CRLF.length
                    continue
                }

                let data: NSData = self.sourceData.subdataWithRange(NSMakeRange(cursor, boundaryPosition.location - cursor))

                self.programInformations.append(TVProgramInfo(data: data))

                if boundaryPosition.location == terminatorPosition.location {
                    break
                }
                cursor = boundaryPosition.location + boundaryPosition.length + CRLF.length
            }
        }
    }
    
}

