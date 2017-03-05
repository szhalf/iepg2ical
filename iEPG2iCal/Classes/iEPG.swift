//
//  iEPG.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation

class iEPG {
    var programInformations: [TVProgramInfo]

    private let CRLF: NSData = NSData(bytes: "\r\n".UTF8String, length: 2)

    private var _data: NSData

    init(data: NSData) throws {
        programInformations = []
        _data               = data

        try self.parse()
    }

    convenience init(let path: String) throws {
        try self.init(data: NSData(contentsOfFile: path)!)
    }

    private func parse() throws {
        // searching content mime type and boundary
        var contentType: String?
        var encoding:    NSStringEncoding = NSASCIIStringEncoding
        var boundary:    String?

        var cursor: Int = 0
        while cursor < self._data.length {
            let range1: NSRange = self._data.rangeOfData(CRLF, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(cursor, self._data.length - cursor))

            if range1.location == NSNotFound {
                break
            }

            if cursor == range1.location {
                cursor = range1.location + CRLF.length
                break
            }

            let lineData: NSData = self._data.subdataWithRange(NSMakeRange(cursor, range1.location - cursor))
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

        if contentType?.lowercaseString == "application/x-tv-program-info"
                || contentType?.lowercaseString == "application/x-tv-program-digital-info" {
            try self.programInformations.append(TVProgramInfo(data: self._data))
        } else if contentType?.lowercaseString == "application/x-multi-tv-program-info"
                || contentType?.lowercaseString == "application/x-multi-tv-program-digital-info" {
            if boundary == nil {
                return
            }

            let boundaryData: NSMutableData = NSMutableData(data: CRLF)
            boundaryData.appendData(boundary!.dataUsingEncoding(encoding)!)

            let terminatorData: NSMutableData = NSMutableData(data: boundaryData)
            terminatorData.appendData(NSString(string: "--").dataUsingEncoding(encoding)!)

            while cursor < self._data.length {
                let range:              NSRange = NSMakeRange(cursor, self._data.length - cursor)
                let boundaryPosition:   NSRange = self._data.rangeOfData(boundaryData, options:NSDataSearchOptions(rawValue: 0), range:range)
                let terminatorPosition: NSRange = self._data.rangeOfData(terminatorData, options:NSDataSearchOptions(rawValue: 0), range:range)

                if boundaryPosition.location == NSNotFound {
                    break
                }
                if cursor == boundaryPosition.location {
                    cursor = boundaryPosition.location + boundaryPosition.length + CRLF.length
                    continue
                }

                let data: NSData = self._data.subdataWithRange(NSMakeRange(cursor, boundaryPosition.location - cursor))

                try self.programInformations.append(TVProgramInfo(data: data))

                if boundaryPosition.location == terminatorPosition.location {
                    break
                }
                cursor = boundaryPosition.location + boundaryPosition.length + CRLF.length
            }
        }
    }
    
}

