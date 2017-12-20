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
var outputName            = ""
var outputArray: [String] = []

let searchPath = ("~/Downloads" as NSString).standardizingPath
let n = searchPath.completePath(into: &outputName, caseSensitive: Bool(false), matchesInto: &outputArray, filterTypes: ["tvpi", "tvpid"])

for path in outputArray {
    if (path as NSString).pathExtension.count > 0 {
        filePaths.append(path)
    }
}

if (filePaths.count == 0) {
    print("no iEPG files found")
    exit(1)
}

var eventStore          = EKEventStore()
var authorizationStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)

switch authorizationStatus {
case .authorized:
    break

case .notDetermined:
    eventStore.requestAccess(to: EKEntityType.event, completion: { (granted: Bool, e: Error?) in
        if (granted) {
            print("granted")
        }
        } as EKEventStoreRequestAccessCompletionHandler)

case .restricted:
    print("restricted")

case .denied:
    print("denied")

}

var calendarIdentifier: String? = nil
for c: EKCalendar in eventStore.calendars(for: EKEntityType.event) {
    if c.title == calendarName {
        calendarIdentifier = c.calendarIdentifier
        break
    }
}

let calendar: EKCalendar
if let ci = calendarIdentifier,
    let cal = eventStore.calendar(withIdentifier: ci) {
    calendar = cal
} else {
    print("Calendar was not found")
    exit(1)
}

var iepgs: [iEPG] = []
for path in filePaths {
    iepgs.append(try iEPG(path: path))
}

let converter = Converter(withEventStore: eventStore)
converter.stationReplaceMap        = stationReplaceMap
converter.defaultEventAvailability = EKEventAvailability.free

for iepg in iepgs {
    converter.addTVPrograms(iepg.programInformations)
}

try converter.saveToCalendar(calendar)
