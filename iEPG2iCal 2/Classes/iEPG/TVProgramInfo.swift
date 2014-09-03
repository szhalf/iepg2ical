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
    var genre:         NSNumber?
    var memo:          NSString?
    var performer:     NSString?
    var startDateTime: NSDate?
    var station:       NSString?
    var subGenre:      NSNumber?
    var subtitle:      NSString?
    var title:         NSString?
    var version:       NSString?

    init(let data: NSData) {
        self.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        self.encoding = NSASCIIStringEncoding
        self.data     = data

        self.parse()
    }

    func parse() {
        let calendarUnitFlags: NSCalendarUnit = .YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit

        let dateComponentsStart: NSDateComponents = self.calendar.components(calendarUnitFlags, fromDate: NSDate())
        let dateComponentsEnd:   NSDateComponents = self.calendar.components(calendarUnitFlags, fromDate: NSDate())

        var headerPartEnds: Bool = false
        var cursor:         Int  = 0
        while cursor < self.data?.length {
            let range1: NSRange = self.data!.rangeOfData(CRLF, options:NSDataSearchOptions(0), range:NSMakeRange(cursor, self.data!.length - cursor))

            if range1.location == NSNotFound {
                break
            }

            headerPartEnds = cursor == range1.location

            if (!headerPartEnds) {
                let lineData: NSData   = self.data!.subdataWithRange(NSMakeRange(cursor, range1.location - cursor))
                let line:     NSString = NSString(data: lineData, encoding: encoding)
                let range2:   NSRange  = line.rangeOfString(":")

                let name:  NSString = line.substringToIndex(range2.location).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let value: NSString = line.substringFromIndex(range2.location + range2.length).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

                switch name {
                case let name where name.isCaseInsensitiveLike("content-type"):
                    (_, self.encoding) = Utils.parseContentType(value)

                case let name where name .isCaseInsensitiveLike("version"):

                    self.version = value
                case let name where name.isCaseInsensitiveLike("station"):
                    self.station = value

                case let name where name.isCaseInsensitiveLike("year"):
                    dateComponentsStart.setValue(value.integerValue, forComponent: NSCalendarUnit.YearCalendarUnit)
                    dateComponentsEnd.setValue(value.integerValue, forComponent: NSCalendarUnit.YearCalendarUnit)

                case let name where name.isCaseInsensitiveLike("month"):
                    dateComponentsStart.setValue(value.integerValue, forComponent: NSCalendarUnit.MonthCalendarUnit)
                    dateComponentsEnd.setValue(value.integerValue, forComponent: NSCalendarUnit.MonthCalendarUnit)

                case let name where name.isCaseInsensitiveLike("date"):
                    dateComponentsStart.setValue(value.integerValue, forComponent: NSCalendarUnit.DayCalendarUnit)
                    dateComponentsEnd.setValue(value.integerValue, forComponent: NSCalendarUnit.DayCalendarUnit)

                case let name where name.isCaseInsensitiveLike("start"):
                    self.setTime(value, dateComponents: dateComponentsStart)

                case let name where name.isCaseInsensitiveLike("end"):
                    self.setTime(value, dateComponents: dateComponentsEnd)

                case let name where name.isCaseInsensitiveLike("program-title"):
                    self.title = value

                case let name where name.isCaseInsensitiveLike("program-subtitle"):
                    self.subtitle = value

                case let name where name.isCaseInsensitiveLike("performer"):
                    self.performer = value

                case let name where name.isCaseInsensitiveLike("genre"):
                    self.genre = NSNumber(integer: value.integerValue)
                    
                case let name where name.isCaseInsensitiveLike("subgenre"):
                    self.subGenre = NSNumber(integer: value.integerValue)
                    
                default:
                    break
                }
                
            } else {
                cursor += CRLF.length
                self.memo = NSString(data: self.data!.subdataWithRange(NSMakeRange(cursor, self.data!.length - cursor)), encoding: self.encoding)
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
        let array: NSArray = string.componentsSeparatedByString(":")

        var hour:   Int = array.objectAtIndex(0).integerValue
        var minute: Int = array.objectAtIndex(1).integerValue

        if (hour > 24) {
            dateComponents.setValue(dateComponents.day + 1, forComponent: NSCalendarUnit.DayCalendarUnit)
            hour -= 24
        }

        dateComponents.setValue(hour, forComponent: NSCalendarUnit.HourCalendarUnit)
        dateComponents.setValue(minute, forComponent: NSCalendarUnit.MinuteCalendarUnit)
    }

}
