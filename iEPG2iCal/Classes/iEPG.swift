//
//  iEPG.swift
//  iEPG2iCal
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation

class iEPG {
    var programInformations: [TVProgramInfo]

    fileprivate static let CRLF      = "\r\n"
    fileprivate static let CRLF_DATA = CRLF.data(using: String.Encoding.utf8)!

    fileprivate var _data: Data

    init(data: Data) throws {
        programInformations = []
        _data               = data

        try self.parse()
    }

    convenience init(path: String) throws {
        try self.init(data: Data(contentsOf: URL(fileURLWithPath: path)))
    }

    fileprivate func parse() throws {
        // searching content mime type and boundary
        var optionalContentType: String?
        var encoding:            String.Encoding = String.Encoding.ascii
        var optionalBoundary:    String?

        var cursor: Int = 0
        while cursor < self._data.count {
            guard let range1 = self._data.range(of: iEPG.CRLF_DATA, options: Data.SearchOptions(rawValue: 0), in: Range<Data.Index>(uncheckedBounds: (cursor, self._data.count))) else {
                break;
            }

            if cursor == range1.lowerBound {
                cursor = range1.lowerBound + iEPG.CRLF_DATA.count
                break
            }

            let lineData: Data   = self._data.subdata(in: Range(uncheckedBounds: (cursor, range1.lowerBound)))
            let line:     String = String(data: lineData, encoding: String.Encoding.ascii)!

            let (name, value) = Utils.splitStringIntoKeyAndValue(line, delimiter: ":")

            switch name.lowercased() {
            case "content-type":
                (optionalContentType, encoding) = Utils.parseContentType(value)

            case "boundary":
                optionalBoundary = value

            default:
                break
            }

            cursor = range1.lowerBound + iEPG.CRLF_DATA.count
        }

        if optionalContentType?.lowercased() == "application/x-tv-program-info"
                || optionalContentType?.lowercased() == "application/x-tv-program-digital-info" {
            try self.programInformations.append(TVProgramInfo(data: self._data))
        } else if optionalContentType?.lowercased() == "application/x-multi-tv-program-info"
                || optionalContentType?.lowercased() == "application/x-multi-tv-program-digital-info" {
            if optionalBoundary == nil {
                return
            }

            let boundaryData:   Data = (iEPG.CRLF + optionalBoundary!).data(using: encoding)!
            let terminatorData: Data = (iEPG.CRLF + optionalBoundary! + "--").data(using: encoding)!

            while cursor < self._data.count {
                let range: Range = Range(uncheckedBounds: (cursor, self._data.count))

                guard
                    let boundaryPosition:   Range = self._data.range(of: boundaryData, options:Data.SearchOptions(rawValue: 0), in:range),
                    let terminatorPosition: Range = self._data.range(of: terminatorData, options:Data.SearchOptions(rawValue: 0), in:range) else {
                    break
                }

                if cursor == boundaryPosition.lowerBound {
                    cursor = boundaryPosition.upperBound + iEPG.CRLF_DATA.count
                    continue
                }

                let data: Data = self._data.subdata(in: Range(uncheckedBounds: (cursor, boundaryPosition.lowerBound)))

                try self.programInformations.append(TVProgramInfo(data: data))

                if boundaryPosition.lowerBound == terminatorPosition.lowerBound {
                    break
                }
                cursor = boundaryPosition.upperBound + iEPG.CRLF_DATA.count
            }
        }
    }
    
}

