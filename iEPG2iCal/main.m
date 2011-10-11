//
//  main.m
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 4/29/11.
//  Copyright 2011 sz50.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>
#import "iEPG.h"
#import "TVProgramInfo.h"


void parse (NSData *data);

int main (int argc, const char * argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *stationNumbers = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"1", @"ＮＨＫ総合" 
                                    ,@"2", @"ＮＨＫ教育" 
                                    ,@"4", @"日本テレビ" 
                                    ,@"5", @"テレビ朝日" 
                                    ,@"6", @"ＴＢＳテレビ"
                                    ,@"7", @"テレビ東京" 
                                    ,@"8", @"フジテレビ" 
                                    ,@"9", @"ＭＸテレビ" 
                                    , nil];
    
    
    NSMutableArray *filePaths = [NSMutableArray array];
    
    NSString *searchPath = [@"~/Downloads" stringByExpandingTildeInPath];
    NSString *outputName;
    NSArray *outputArray;
    [searchPath completePathIntoString:&outputName 
                         caseSensitive:NO
                      matchesIntoArray:&outputArray
                           filterTypes:[NSArray arrayWithObject:@"tvpi"]];
    for (NSString *path in outputArray) {
        if ([path.pathExtension isCaseInsensitiveLike:@"tvpi"]) {
            [filePaths addObject:path];
        }
    }
    
    if (filePaths == nil || filePaths.count == 0) {
        printf("no iEPG files found");
        exit(1);
    }
    
    CalCalendarStore *calendarStore = [CalCalendarStore defaultCalendarStore];
    CalCalendar *calendar = nil;
    for (calendar in [calendarStore calendars]) {
        if ([calendar.title isEqualToString:@"Check"]) {
            break;
        }
    }
    
    NSMutableArray *programs = [NSMutableArray array];
    for (NSString *path in filePaths) {
        iEPG     *iepg1 = [iEPG iEPGWithContentsOfFile:path];
        [programs addObjectsFromArray:iepg1.programInformations];
    }
    
    for (TVProgramInfo *program in programs) {
        NSString *programStation = program.station;
        programStation = [programStation stringByReplacingOccurrencesOfString:@"SPTV"
                                                                   withString:@"CS"];
        programStation = [programStation stringByReplacingOccurrencesOfString:@"BSDT" 
                                                                   withString:@"BS"];
        if ([stationNumbers objectForKey:programStation]) {
            programStation = [stationNumbers objectForKey:programStation];
        }
        
        NSString *memo = program.memo;
        memo = [memo stringByReplacingOccurrencesOfString:@"<BR>" 
                                               withString:@"\r\n"
                                                  options:NSCaseInsensitiveSearch 
                                                    range:NSMakeRange(0, program.memo.length)];
        
        CalEvent *event = [CalEvent event];
        event.calendar  = calendar;
        event.title     = [NSString stringWithFormat:@"[%@] %@", programStation, program.title];
        event.startDate = program.startDateTime;
        event.endDate   = program.endDateTime;
        event.notes     = memo;
        
        NSError *error = nil;
        [calendarStore saveEvent:event span:CalSpanAllEvents error:&error];
        if (error != nil) {
            NSLog(@"%@", error);
        }
    }
    
    [pool drain];
    return 0;
}
