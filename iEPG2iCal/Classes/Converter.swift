//
//  Converter.swift
//  iEPG2iCal
//
//  Created by Wataru SUZUKI on 9/23/15.
//  Copyright © 2015 sz50.com. All rights reserved.
//

import EventKit

class Converter: NSObject {
    var stationReplaceMap:        [String: String]
    var defaultEventAvailability: EKEventAvailability

    private let _eventStore:     EKEventStore
    private var _events:         [EKEvent]?
    private var _tvProgramInfos: [TVProgramInfo]

    init(withEventStore store: EKEventStore) {
        _eventStore     = store
        _events         = nil
        _tvProgramInfos = [TVProgramInfo]()

        stationReplaceMap        = [String: String]()
        defaultEventAvailability = EKEventAvailability.Free
    }

    private func convertStationName(var string: String) -> String {
        for (original, replaced) in self.stationReplaceMap {
            string = string.stringByReplacingOccurrencesOfString(original, withString:replaced)
        }

        return string
    }

    func addTVProgram(programs: TVProgramInfo) {
        _tvProgramInfos.append(programs)
    }

    func addTVPrograms(programs: [TVProgramInfo]) {
        _tvProgramInfos += programs
    }

    func setTVPrograms(programs: [TVProgramInfo]) {
        _tvProgramInfos = programs
    }

    func convert() -> [EKEvent] {
        self._events = []

        for program in _tvProgramInfos {
            let station: String = self.convertStationName(program.station)

            let event: EKEvent = EKEvent(eventStore: self._eventStore)

            event.title        = !station.isEmpty ? NSString(format: "[%@] ", station) as String + program.title : program.title
            event.startDate    = program.startDateTime
            event.endDate      = program.endDateTime
            event.availability = self.defaultEventAvailability
            event.notes        = program.memo.stringByReplacingOccurrencesOfString("<BR>", withString:"\r\n", options: NSStringCompareOptions.CaseInsensitiveSearch)

            self._events! += [event]
        }

        return self._events!
    }

    func convert(tvPrograms: [TVProgramInfo]) -> [EKEvent] {
        _tvProgramInfos = tvPrograms

        return self.convert()
    }

    func saveToCalendar(calendar: EKCalendar) throws {
        if self._events == nil {
            self.convert()
        }

        if (self._events?.count < 1) {
            return
        }

        for event in self._events! {
            event.calendar = calendar
            try eventStore.saveEvent(event, span: EKSpan.ThisEvent, commit: false)
        }

        try eventStore.commit()
    }
}
