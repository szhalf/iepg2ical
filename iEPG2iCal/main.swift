//
//  main.swift
//  iEPG2iCal 2
//
//  Created by Wataru SUZUKI on 8/3/14.
//  Copyright (c) 2014 sz50.com. All rights reserved.
//

import Foundation
import EventKit

let calendarName      = "TV/Check"
let stationReplaceMap = [
    "ＮＨＫ総合"   : "1",
    "ＮＨＫ教育"   : "2",
    "日本テレビ"   : "4",
    "テレビ朝日"   : "5",
    "ＴＢＳテレビ" : "6",
    "テレビ東京"   : "7",
    "フジテレビ"   : "8",
    "ＭＸテレビ"   : "9",
    "ＮＨＫ衛星第一": "BS101",
    "DFS00400"   : "011",
    "DFS00408"   : "021",
    "DFS00410"   : "041",
    "DFS00428"   : "051",
    "DFS00418"   : "061",
    "DFS00430"   : "071",
    "DFS00420"   : "081",
    "DFS05C38"   : "091",
    "SPTV"       : "CS",
    "BSDT"       : "BS",
    "CSDT"       : "CS"
]

var filePaths:   [String] = []
var outputName:  NSString?
var outputArray: NSArray?

var searchPath:  NSString  = ("~/Downloads" as NSString).stringByExpandingTildeInPath
searchPath.completePathIntoString(&outputName, caseSensitive: Bool(false), matchesIntoArray: &outputArray, filterTypes: ["tvpi", "tvpid"])

for path in outputArray as! [String] {
    var pathExtention = NSString(string: (path as NSString).pathExtension)
    if pathExtention.length > 0 {
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

var calendarIdentifier: String! = nil
for var c: EKCalendar in eventStore.calendarsForEntityType(EKEntityType.Event) {
    if c.title == calendarName {
        calendarIdentifier = c.calendarIdentifier
        break
    }
}

var calendar: EKCalendar? = eventStore.calendarWithIdentifier(calendarIdentifier)
if (calendar == nil) {
    print("Calendar was not found")
    exit(1)
}

var iepgs: [iEPG] = []
for path in filePaths {
    iepgs.append(try iEPG(path: path))
}

let converter = Converter(withEventStore: eventStore)
converter.stationReplaceMap        = stationReplaceMap
converter.defaultEventAvailability = EKEventAvailability.Free

for iepg in iepgs {
    converter.addTVPrograms(iepg.programInformations)
}


try converter.saveToCalendar(calendar!)
