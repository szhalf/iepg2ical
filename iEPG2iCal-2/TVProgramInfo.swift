//
//  TVProgramInfo.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Cocoa

class TVProgramInfo {
    let CRLF: NSData = NSData(bytes: "\r\n".UTF8String, length: 2)

    var calendar:      NSCalendar
    var data:          NSData?
    var encoding:      NSStringEncoding
    var endDateTime:   NSDate?
    var genre:         Int?
    var memo:          String?
    var performer:     String?
    var startDateTime: NSDate?
    var station:       String?
    var subGenre:      Int?
    var subtitle:      String?
    var title:         String?
    var version:       String?

    init(let data: NSData) {
        self.calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        self.encoding = NSASCIIStringEncoding
        self.data     = data

        self.parse()
    }

    func parse() {
        var calendarUnitFlags: NSCalendarUnit = NSCalendarUnit()
        calendarUnitFlags.insert(NSCalendarUnit.Year)
        calendarUnitFlags.insert(NSCalendarUnit.Month)
        calendarUnitFlags.insert(NSCalendarUnit.Day)

        let now = NSDate()
        let dateComponentsStart: NSDateComponents = self.calendar.components(calendarUnitFlags, fromDate: now)
        let dateComponentsEnd:   NSDateComponents = self.calendar.components(calendarUnitFlags, fromDate: now)

        var headerPartEnds: Bool = false
        var cursor:         Int  = 0
        while cursor < self.data?.length {
            let range1: NSRange = self.data!.rangeOfData(CRLF, options:NSDataSearchOptions(rawValue: 0), range:NSMakeRange(cursor, self.data!.length - cursor))

            if range1.location == NSNotFound {
                break
            }

            headerPartEnds = cursor == range1.location

            if (!headerPartEnds) {
                let lineData: NSData = self.data!.subdataWithRange(NSMakeRange(cursor, range1.location - cursor))
                let line:     String = NSString(data: lineData, encoding: encoding)! as String

                let (name, value) = Utils.splitStringIntoKeyAndValue(line, delimiter: ":")

                switch name.lowercaseString {
                case "content-type":
                    (_, self.encoding) = Utils.parseContentType(value as String)

                case "version":
                    self.version = value

                case "station":
                    self.station = value

                case "year":
                    dateComponentsStart.setValue(Int(value)!, forComponent: NSCalendarUnit.Year)
                    dateComponentsEnd.setValue(Int(value)!, forComponent: NSCalendarUnit.Year)

                case "month":
                    dateComponentsStart.setValue(Int(value)!, forComponent: NSCalendarUnit.Month)
                    dateComponentsEnd.setValue(Int(value)!, forComponent: NSCalendarUnit.Month)

                case "date":
                    dateComponentsStart.setValue(Int(value)!, forComponent: NSCalendarUnit.Day)
                    dateComponentsEnd.setValue(Int(value)!, forComponent: NSCalendarUnit.Day)

                case "start":
                    self.setTime(value as String, dateComponents: dateComponentsStart)

                case "end":
                    self.setTime(value as String, dateComponents: dateComponentsEnd)

                case "program-title":
                    self.title = value

                case "program-subtitle":
                    self.subtitle = value

                case "performer":
                    self.performer = value

                case "genre":
                    self.genre = Int(value)!

                case "subgenre":
                    self.subGenre = Int(value)!

                default:
                    break
                }

            } else {
                cursor += CRLF.length
                self.memo = NSString(data: self.data!.subdataWithRange(NSMakeRange(cursor, self.data!.length - cursor)), encoding: self.encoding) as String?
                break
            }
            cursor = range1.location + CRLF.length
        }

        self.startDateTime = self.calendar.dateFromComponents(dateComponentsStart)
        self.endDateTime   = self.calendar.dateFromComponents(dateComponentsEnd)

        if (self.startDateTime!.compare(self.endDateTime!) == NSComparisonResult.OrderedDescending) {
            self.endDateTime = self.endDateTime?.dateByAddingTimeInterval(NSTimeInterval(60 * 60 * 24))
        }
    }

    func setTime(let string: String, let dateComponents: NSDateComponents) {
        let array: [String] = string.componentsSeparatedByString(":")

        var hour:   Int = Int(array[0])!
        let minute: Int = Int(array[1])!

        if (hour > 24) {
            dateComponents.setValue(dateComponents.day + 1, forComponent: NSCalendarUnit.Day)
            hour -= 24
        }

        dateComponents.setValue(hour, forComponent: NSCalendarUnit.Hour)
        dateComponents.setValue(minute, forComponent: NSCalendarUnit.Minute)
    }
    
}
