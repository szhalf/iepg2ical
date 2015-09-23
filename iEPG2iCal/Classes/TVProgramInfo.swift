//
//  TVProgramInfo.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation

class TVProgramInfo {
    enum FieldError: ErrorType {
        case YearValueUnspecified
        case MonthValueUnspecified
        case DateValueUnspecified
        case TimeValueUnspecified
        case StartValueUnspecified
        case EndValueUnspecified
    }

    var startDateTime: NSDate {
        return _startDateTime!
    }
    var endDateTime: NSDate {
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

    private let CRLF: NSData = NSData(bytes: "\r\n".UTF8String, length: 2)

    private var _data:          NSData
    private var _encoding:      NSStringEncoding
    private var _version:       String?
    private var _startDateTime: NSDate?
    private var _endDateTime:   NSDate?
    private var _station:       String?
    private var _title:         String?
    private var _subtitle:      String?
    private var _memo:          String?
    private var _performer:     String?
    private var _year:          Int?
    private var _month:         Int?
    private var _date:          Int?
    private var _timeStart:     String?
    private var _timeEnd:       String?

    init(let data: NSData) throws {
        _encoding = NSASCIIStringEncoding
        _data     = data

        try self.parse()
    }

    private func parse() throws {
        var headerPartEnds: Bool = false
        var cursor:         Int  = 0
        while cursor < _data.length {
            let range1: NSRange = _data.rangeOfData(CRLF, options:NSDataSearchOptions(rawValue: 0), range:NSMakeRange(cursor, _data.length - cursor))

            if range1.location == NSNotFound {
                break
            }

            headerPartEnds = cursor == range1.location

            if (!headerPartEnds) {
                let lineData: NSData = _data.subdataWithRange(NSMakeRange(cursor, range1.location - cursor))
                let line:     String = NSString(data: lineData, encoding: _encoding)! as String

                let (name, value) = Utils.splitStringIntoKeyAndValue(line, delimiter: ":")

                switch name.lowercaseString {
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
                cursor += CRLF.length
                _memo = NSString(data: _data.subdataWithRange(NSMakeRange(cursor, _data.length - cursor)), encoding: _encoding) as String?
                break
            }
            cursor = range1.location + CRLF.length
        }

        do {
            try _startDateTime = self.makeDate(year: _year, month: _month, date: _date, time: _timeStart)
        } catch FieldError.TimeValueUnspecified {
            throw FieldError.StartValueUnspecified
        }

        do {
            try _endDateTime = self.makeDate(year: _year, month: _month, date: _date, time: _timeEnd)
        } catch FieldError.TimeValueUnspecified {
            throw FieldError.EndValueUnspecified
        }

        if (_startDateTime!.compare(_endDateTime!) == NSComparisonResult.OrderedDescending) {
            _endDateTime = _endDateTime!.dateByAddingTimeInterval(NSTimeInterval(60 * 60 * 24))
        }
    }

    private func makeDate(let year year: Int?, let month: Int?, let date: Int?, let time: String?) throws -> NSDate {
        if (year == nil) {
            throw FieldError.YearValueUnspecified
        }

        if (month == nil) {
            throw FieldError.MonthValueUnspecified
        }

        if (date == nil) {
            throw FieldError.DateValueUnspecified
        }

        if (time == nil) {
            throw FieldError.TimeValueUnspecified
        }

        let array:  [String]  = time!.componentsSeparatedByString(":")
        let hour:   Int       = Int(array[0])!
        let minute: Int       = Int(array[1])!
        let now               = NSDate()
        let calendar          = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        var calendarUnitFlags = NSCalendarUnit()

        calendarUnitFlags.insert(NSCalendarUnit.Year)
        calendarUnitFlags.insert(NSCalendarUnit.Month)
        calendarUnitFlags.insert(NSCalendarUnit.Day)

        let components: NSDateComponents = calendar.components(calendarUnitFlags, fromDate: now)

        components.setValue(year!, forComponent: NSCalendarUnit.Year)
        components.setValue(month!, forComponent: NSCalendarUnit.Month)
        components.setValue(date!, forComponent: NSCalendarUnit.Day)
        components.setValue(hour < 24 ? hour : hour - 24, forComponent: NSCalendarUnit.Hour)
        components.setValue(minute, forComponent: NSCalendarUnit.Minute)

        if (hour >= 24) {
            components.setValue(components.day + 1, forComponent: NSCalendarUnit.Day)
        }

        return calendar.dateFromComponents(components)!
    }

}
