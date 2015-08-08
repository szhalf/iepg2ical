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
    "ＮＨＫ総合": "1",
    "2": "ＮＨＫ教育",
    "4": "日本テレビ",
    "5": "テレビ朝日",
    "6": "ＴＢＳテレビ",
    "7": "テレビ東京",
    "8": "フジテレビ",
    "9": "ＭＸテレビ"
]

var filePaths:   [String] = [];
var outputName:  NSString?
var outputArray: NSArray?

var searchPath:  NSString  = ("~/Downloads" as NSString).stringByExpandingTildeInPath;
searchPath.completePathIntoString(&outputName, caseSensitive: Bool(false), matchesIntoArray: &outputArray, filterTypes: ["tvpi"])

for path in outputArray as! [String] {
    var pathExtention = NSString(string: (path as NSString).pathExtension);
    if pathExtention.isCaseInsensitiveLike("tvpi") {
        filePaths.append(path);
    }
}

if (filePaths.count == 0) {
    print("no iEPG files found");
    exit(1);
}

var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatusForEntityType(EKEntityMask.Event)

switch authorizationStatus {
case .Authorized:
    print("authorized")
case .NotDetermined:
    print("not determined")
case .Restricted:
    print("restricted")
case .Denied:
    print("denied")
}

var eventStore: EKEventStore = EKEventStore()
//eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: { (b: Bool, e: NSError!) in
//    println(123123)
//    })

var calendars = eventStore.calendarsForEntityType(EKEntityType.Event)

var calendar: EKCalendar;
for c in calendars {
    calendar = c as EKCalendar
    if calendar.title == "Check" {
        break;
    }
}

var programs: [TVProgramInfo] = [];
for path in filePaths {
    var iepg1: iEPG = iEPG(path: path)
    programs + iepg1.programInformations
}

for program in programs {
    var station: String? = program.station
    var memo = program.memo

    if station != nil {
        station = station!.stringByReplacingOccurrencesOfString("SPTV", withString:"CS")
        station = station!.stringByReplacingOccurrencesOfString("BSDT", withString:"BS")
        if stationNumbers[station!] != nil {
            station = stationNumbers[station!];
        }
    }

    if memo != nil {
        memo = memo!.stringByReplacingOccurrencesOfString("<BR>", withString:"\r\n", options: NSStringCompareOptions.CaseInsensitiveSearch);
    }

//    CalEvent *event = [CalEvent event];
//    event.calendar  = calendar;
//    event.title     = [NSString stringWithFormat:@"[%@] %@", station, program.title];
//    event.startDate = program.startDateTime;
//    event.endDate   = program.endDateTime;
//    event.notes     = memo;
//
//    NSError *error = nil;
//    [calendarStore saveEvent:event span:CalSpanAllEvents error:&error];
//    if (error != nil) {
//        NSLog(@"%@", error);
//    }
}

