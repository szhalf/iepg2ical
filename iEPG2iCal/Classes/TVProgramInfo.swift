//
//  TVProgramInfo.swift
//  iEPG2iCal
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation

class TVProgramInfo {
    enum FieldError: Error {
        case yearValueUnspecified
        case monthValueUnspecified
        case dateValueUnspecified
        case timeValueUnspecified
        case startValueUnspecified
        case endValueUnspecified
    }

    var startDateTime: Date {
        return _startDateTime!
    }
    var endDateTime: Date {
        return _endDateTime!
    }
    var station: String {
        return _station != nil ? _station! : ""
    }
    var genre:    Int?
    var subGenre: Int?
    var title: String {
        return _title != nil ? _title! : ""
    }
    var subtitle: String {
        return _subtitle != nil ? _subtitle! : ""
    }
    var memo: String {
        return _memo != nil ? _memo! : ""
    }
    var performer: String {
        return _performer != nil ? _performer! : ""
    }

    fileprivate static let CRLF      = "\r\n"
    fileprivate static let CRLF_DATA = CRLF.data(using: String.Encoding.utf8)!

    fileprivate var _data:          Data
    fileprivate var _encoding:      String.Encoding
    fileprivate var _version:       String?
    fileprivate var _startDateTime: Date?
    fileprivate var _endDateTime:   Date?
    fileprivate var _station:       String?
    fileprivate var _title:         String?
    fileprivate var _subtitle:      String?
    fileprivate var _memo:          String?
    fileprivate var _performer:     String?
    fileprivate var _year:          Int?
    fileprivate var _month:         Int?
    fileprivate var _date:          Int?
    fileprivate var _timeStart:     String?
    fileprivate var _timeEnd:       String?

    init(data: Data) throws {
        _encoding = String.Encoding.ascii
        _data     = data

        try self.parse()
    }

    fileprivate func parse() throws {
        var headerPartEnds = false
        var cursor         = 0
        while cursor < _data.count {
            guard let range1 = _data.range(of: TVProgramInfo.CRLF_DATA, options: Data.SearchOptions(rawValue: 0), in: Range<Data.Index>(uncheckedBounds: (cursor, _data.count))) else {
                break
            }

            headerPartEnds = cursor == range1.lowerBound

            if !headerPartEnds {
                let line = String(data: _data.subdata(in: Range(uncheckedBounds: (cursor, range1.lowerBound))), encoding: _encoding)!

                let (name, value) = Utils.splitStringIntoKeyAndValue(line, delimiter: ":")

                switch name.lowercased() {
                case "content-type":
                    (_, _encoding) = Utils.parseContentType(value as String)

                case "version":
                    _version = value

                case "station":
                    _station = value

                case "year":
                    _year = Int(value)

                case "month":
                    _month = Int(value)

                case "date":
                    _date = Int(value)

                case "start":
                    _timeStart = value

                case "end":
                    _timeEnd = value

                case "program-title":
                    _title = value

                case "program-subtitle":
                    _subtitle = value

                case "performer":
                    _performer = value

                case "genre":
                    self.genre = Int(value)!

                case "subgenre":
                    self.subGenre = Int(value)!

                default:
                    break
                }

            } else {
                cursor += TVProgramInfo.CRLF_DATA.count
                _memo = String(data: _data.subdata(in: Range(uncheckedBounds: (cursor, _data.count))), encoding: _encoding) as String?
                break
            }
            cursor = range1.lowerBound + TVProgramInfo.CRLF_DATA.count
        }

        do {
            try _startDateTime = self.makeDate(claimedYear: _year, claimedMonth: _month, claimedDate: _date, claimedTime: _timeStart)
        } catch FieldError.timeValueUnspecified {
            throw FieldError.startValueUnspecified
        }

        do {
            try _endDateTime = self.makeDate(claimedYear: _year, claimedMonth: _month, claimedDate: _date, claimedTime: _timeEnd)
        } catch FieldError.timeValueUnspecified {
            throw FieldError.endValueUnspecified
        }

        if _startDateTime!.compare(_endDateTime!) == ComparisonResult.orderedDescending {
            _endDateTime = _endDateTime!.addingTimeInterval(TimeInterval(60 * 60 * 24))
        }
    }

    fileprivate func makeDate(claimedYear: Int?, claimedMonth: Int?, claimedDate: Int?, claimedTime: String?) throws -> Date {
        if claimedYear == nil {
            throw FieldError.yearValueUnspecified
        }

        if claimedMonth == nil {
            throw FieldError.monthValueUnspecified
        }

        if claimedDate == nil {
            throw FieldError.dateValueUnspecified
        }

        if claimedTime == nil {
            throw FieldError.timeValueUnspecified
        }

        let array  = claimedTime!.components(separatedBy: ":")
        let hour   = Int(array[0])!
        let minute = Int(array[1])!

        let calendar       = Calendar(identifier: Calendar.Identifier.gregorian)
        let components     = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day] as Set<Calendar.Component>
        var dateComponents = calendar.dateComponents(components, from: Date())

        dateComponents.setValue(claimedYear, for: Calendar.Component.year)
        dateComponents.setValue(claimedMonth, for: Calendar.Component.month)
        dateComponents.setValue(claimedDate, for: Calendar.Component.day)
        dateComponents.setValue(hour < 24 ? hour : hour - 24, for: Calendar.Component.hour)
        dateComponents.setValue(minute, for: Calendar.Component.minute)

        if hour >= 24 {
            if let day = dateComponents.day {
                dateComponents.setValue(day + 1, for: Calendar.Component.day)
            }
        }

        return calendar.date(from: dateComponents)!
    }

}
