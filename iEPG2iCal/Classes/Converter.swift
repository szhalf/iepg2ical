//
//  Converter.swift
//  iEPG2iCal
//
//  Created by Wataru SUZUKI on 9/23/15.
//  Copyright © 2015 sz50.com. All rights reserved.
//

import EventKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class Converter: NSObject {
    var stationReplaceMap:        [String: String]
    var defaultEventAvailability: EKEventAvailability

    fileprivate let _eventStore:     EKEventStore
    fileprivate var _events:         [EKEvent]?
    fileprivate var _tvProgramInfos: [TVProgramInfo]

    init(withEventStore store: EKEventStore) {
        _eventStore     = store
        _events         = nil
        _tvProgramInfos = [TVProgramInfo]()

        stationReplaceMap        = [String: String]()
        defaultEventAvailability = EKEventAvailability.free
    }

    private func convertStationName(_ stationName: String) -> String {
        var convertedStationName = stationName
        for (original, replaced) in self.stationReplaceMap {
            convertedStationName = convertedStationName.replacingOccurrences(of: original, with:replaced)
        }

        return convertedStationName
    }

    func addTVPrograms(_ programs: [TVProgramInfo]) {
        _tvProgramInfos += programs
    }

    func convert() -> [EKEvent] {
        self._events = []

        for program in _tvProgramInfos {
            let station = self.convertStationName(program.station)

            let event = EKEvent(eventStore: self._eventStore)

            event.title        = !station.isEmpty ? NSString(format: "[%@] ", station) as String + program.title : program.title
            event.startDate    = program.startDateTime as Date
            event.endDate      = program.endDateTime as Date
            event.availability = self.defaultEventAvailability
            event.notes        = program.memo.replacingOccurrences(of: "<BR>", with:"\r\n", options: NSString.CompareOptions.caseInsensitive)

            self._events! += [event]
        }

        return self._events!
    }

    func saveToCalendar(_ calendar: EKCalendar) throws {
        if self._events == nil {
            self.convert()
        }

        if (self._events?.count < 1) {
            return
        }

        for event in self._events! {
            event.calendar = calendar
            try eventStore.save(event, span: EKSpan.thisEvent, commit: false)
        }

        try eventStore.commit()
    }
}
