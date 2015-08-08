//
//  main.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation
import EventKit

let stationNumbers = [
    "ＮＨＫ総合"   : "1",
    "ＮＨＫ教育"   : "2",
    "日本テレビ"   : "4",
    "テレビ朝日"   : "5",
    "ＴＢＳテレビ" : "6",
    "テレビ東京"   : "7",
    "フジテレビ"   : "8",
    "ＭＸテレビ"   : "9",
    "ＮＨＫ衛星第一": "BS101"
]

var filePaths:   [String] = []
var outputName:  NSString?
var outputArray: NSArray?

var searchPath:  NSString  = ("~/Downloads" as NSString).stringByExpandingTildeInPath
searchPath.completePathIntoString(&outputName, caseSensitive: Bool(false), matchesIntoArray: &outputArray, filterTypes: ["tvpi"])

for path in outputArray as! [String] {
    var pathExtention = NSString(string: (path as NSString).pathExtension)
    if pathExtention.isCaseInsensitiveLike("tvpi") {
        filePaths.append(path)
    }
}

if (filePaths.count == 0) {
    print("no iEPG files found")
    exit(1)
}

var eventStore:          EKEventStore          = EKEventStore()
var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)

switch authorizationStatus {
case .Authorized:
    break

case .NotDetermined:
    eventStore.requestAccessToEntityType(EKEntityType.Event, completion: { (granted: Bool, e: NSError?) in
        if (granted) {
            print("granted")
        }
    })

case .Restricted:
    print("restricted")

case .Denied:
    print("denied")

}

var calid: String! = nil
for var c: EKCalendar in eventStore.calendarsForEntityType(EKEntityType.Event) {
    if c.title == "Check" {
        calid = c.calendarIdentifier
        break
    }
}

var c: EKCalendar? = eventStore.calendarWithIdentifier(calid)
if (c == nil) {
    print("Calendar was not found")
    exit(1)
}
var calendar: EKCalendar = c!

var programs: [TVProgramInfo] = []
for path in filePaths {
    var iepg: iEPG = iEPG(path: path)

    programs = programs + iepg.programInformations
}

for program in programs {
    var station: String = program.station != nil ? program.station! : "???"
    var memo:    String = program.memo != nil ? program.memo! : ""

    station = station.stringByReplacingOccurrencesOfString("SPTV", withString:"CS")
    station = station.stringByReplacingOccurrencesOfString("BSDT", withString:"BS")
    if stationNumbers[station] != nil {
        station = stationNumbers[station] != nil ? stationNumbers[station]! : "???"
    }

    memo = memo.stringByReplacingOccurrencesOfString("<BR>", withString:"\r\n", options: NSStringCompareOptions.CaseInsensitiveSearch)

    if (program.startDateTime == nil || program.endDateTime == nil) {
        continue
    }

    var event: EKEvent = EKEvent(eventStore: eventStore)
    event.calendar     = calendar
    event.title        = NSString(format: "[%@] %@", station, program.title != nil ? program.title! : "") as String
    event.startDate    = program.startDateTime!
    event.endDate      = program.endDateTime!
    event.availability = .Free
    event.notes        = memo

    do {
        try eventStore.saveEvent(event, span: EKSpan.ThisEvent, commit: false)
    } catch {
        print("saving error")
    }
}

do {
    try eventStore.commit()
    
} catch {
    print("commiting error")
}
