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
        if let value = _station {
            return value
        } else {
            return ""
        }
    }
    var genre:    Int?
    var subGenre: Int?
    var title: String {
        if let value = _title {
            return value
        } else {
            return ""
        }
    }
    var subtitle: String {
        if let value = _subtitle {
            return value
        } else {
            return ""
        }
    }
    var memo: String {
        if let value = _memo {
            return value
        } else {
            return ""
        }
    }
    var performer: String {
        if let value = _performer {
            return value
        } else {
            return ""
        }
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
        var cursor = 0
        while cursor < _data.count {
            guard let range1 = _data.range(of: TVProgramInfo.CRLF_DATA, options: Data.SearchOptions(rawValue: 0), in: Range<Data.Index>(uncheckedBounds: (cursor, _data.count))) else {
                break
            }

            let headerPartEnds = cursor == range1.lowerBound

            if !headerPartEnds {
                guard let line = String(data: _data.subdata(in: Range(uncheckedBounds: (cursor, range1.lowerBound))), encoding: _encoding) else {
                    cursor = range1.lowerBound + TVProgramInfo.CRLF_DATA.count
                    continue
                }

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
                    self.genre = Int(value)

                case "subgenre":
                    self.subGenre = Int(value)

                default:
                    break
                }

            } else {
                cursor += TVProgramInfo.CRLF_DATA.count
                _memo = String(data: _data.subdata(in: Range(uncheckedBounds: (cursor, _data.count))), encoding: _encoding)
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

        if let start = _startDateTime, let end = _endDateTime {
            if (start.compare(end) == ComparisonResult.orderedDescending) {
                _endDateTime = end.addingTimeInterval(TimeInterval(60 * 60 * 24))
            }
        }
    }

    fileprivate func makeDate(claimedYear: Int?, claimedMonth: Int?, claimedDate: Int?, claimedTime: String?) throws -> Date {
        var claimedHour:   Int? = nil
        var claimedMinute: Int? = nil
        if let time = claimedTime {
            let array = time.components(separatedBy: ":")

            claimedHour   = Int(array[0])
            claimedMinute = Int(array[1])
        }
        
        guard let year = claimedYear else {
            throw FieldError.yearValueUnspecified
        }
        guard let month = claimedMonth else {
            throw FieldError.monthValueUnspecified
        }
        guard let date = claimedDate else {
            throw FieldError.dateValueUnspecified
        }
        guard let hour = claimedHour, let minute = claimedMinute else {
            throw FieldError.timeValueUnspecified
        }

        let calendar       = Calendar(identifier: Calendar.Identifier.gregorian)
        let components     = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day] as Set<Calendar.Component>
        var dateComponents = calendar.dateComponents(components, from: Date())

        dateComponents.setValue(year, for: Calendar.Component.year)
        dateComponents.setValue(month, for: Calendar.Component.month)
        dateComponents.setValue(date, for: Calendar.Component.day)
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
