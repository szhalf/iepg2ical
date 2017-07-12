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
        var headerPartEnds: Bool = false
        var cursor:         Int  = 0
        while cursor < _data.count {
            guard let range1 = _data.range(of: TVProgramInfo.CRLF_DATA, options: Data.SearchOptions(rawValue: 0), in: Range<Data.Index>(uncheckedBounds: (cursor, _data.count))) else {
                break
            }

            headerPartEnds = cursor == range1.lowerBound

            if !headerPartEnds {
                let lineData: Data   = _data.subdata(in: Range(uncheckedBounds: (cursor, range1.lowerBound)))
                let line:     String = String(data: lineData, encoding: _encoding)!

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
            try _startDateTime = self.makeDate(year: _year, month: _month, date: _date, time: _timeStart)
        } catch FieldError.timeValueUnspecified {
            throw FieldError.startValueUnspecified
        }

        do {
            try _endDateTime = self.makeDate(year: _year, month: _month, date: _date, time: _timeEnd)
        } catch FieldError.timeValueUnspecified {
            throw FieldError.endValueUnspecified
        }

        if _startDateTime!.compare(_endDateTime!) == ComparisonResult.orderedDescending {
            _endDateTime = _endDateTime!.addingTimeInterval(TimeInterval(60 * 60 * 24))
        }
    }

    fileprivate func makeDate(year: Int?, month: Int?, date: Int?, time: String?) throws -> Date {
        if year == nil {
            throw FieldError.yearValueUnspecified
        }

        if month == nil {
            throw FieldError.monthValueUnspecified
        }

        if date == nil {
            throw FieldError.dateValueUnspecified
        }

        if time == nil {
            throw FieldError.timeValueUnspecified
        }

        let array:  [String]  = time!.components(separatedBy: ":")
        let hour:   Int       = Int(array[0])!
        let minute: Int       = Int(array[1])!
        let now               = Date()
        let calendar          = Calendar(identifier: Calendar.Identifier.gregorian)
        let calendarUnitFlags: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]

        var components: DateComponents = calendar.dateComponents(calendarUnitFlags, from: now)

        components.setValue(year, for: Calendar.Component.year)
        components.setValue(month, for: Calendar.Component.month)
        components.setValue(date, for: Calendar.Component.day)
        components.setValue(hour < 24 ? hour : hour - 24, for: Calendar.Component.hour)
        components.setValue(minute, for: Calendar.Component.minute)

        if hour >= 24 {
            if let day = components.day {
                components.setValue(day + 1, for: Calendar.Component.day)
            }
        }

        return calendar.date(from: components)!
    }

}
