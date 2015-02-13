//
//  main.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation
import EventKit

let stationNumbers: NSDictionary = NSDictionary(objectsAndKeys:
    "1", "ＮＨＫ総合",
    "2", "ＮＨＫ教育",
    "4", "日本テレビ",
    "5", "テレビ朝日",
    "6", "ＴＢＳテレビ",
    "7", "テレビ東京",
    "8", "フジテレビ",
    "9", "ＭＸテレビ"
)

var filePaths:   NSMutableArray = [];
var searchPath:  NSString       = "~/Downloads".stringByExpandingTildeInPath;
var outputName:  NSString?;
var outputArray: NSArray?;

searchPath.completePathIntoString(&outputName, caseSensitive: Bool(false), matchesIntoArray: &outputArray, filterTypes: NSArray(objects: "tvpi"))

for path in outputArray! {
    var pathExtention = NSString(string: (path as NSString).pathExtension);
    if pathExtention.isCaseInsensitiveLike("tvpi") {
        filePaths.addObject(path);
    }
}

if (filePaths.count == 0) {
    println("no iEPG files found");
    exit(1);
}

var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatusForEntityType(EKEntityMaskEvent)

switch authorizationStatus {
case .Authorized:
    println("authorized")
case .NotDetermined:
    println("not determined")
case .Restricted:
    println("restricted")
case .Denied:
    println("denied")
}

var eventStore: EKEventStore = EKEventStore()
//eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: { (b: Bool, e: NSError!) in
//    println(123123)
//    })

var calendars = eventStore.calendarsForEntityType(EKEntityTypeEvent)

var calendar: EKCalendar;
for c in calendars {
    calendar = c as EKCalendar
    if calendar.title == "Check" {
        break;
    }
}

var programs: NSMutableArray = [];
for path in filePaths {
    var iepg1: iEPG = iEPG(path: path as NSString)
    programs.addObject(iepg1.programInformations)
}

for p in programs {
    var program = p as TVProgramInfo
    var programStation: NSString? = program.station

    programStation = programStation?.stringByReplacingOccurrencesOfString("SPTV", withString:"CS")
    programStation = programStation?.stringByReplacingOccurrencesOfString("BSDT", withString:"BS")
    if stationNumbers.objectForKey(programStation!) != nil {
        programStation = stationNumbers.objectForKey(programStation!) as NSString?;
    }

    //var memo: NSString? = program.memo;
    //memo = memo.stringByReplacingOccurrencesOfString("<BR>", withString:"\r\n", options: NSCaseInsensitiveSearch(range:NSMakeRange(0, program.memo.length)));

//    CalEvent *event = [CalEvent event];
//    event.calendar  = calendar;
//    event.title     = [NSString stringWithFormat:@"[%@] %@", programStation, program.title];
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

