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
    
    /*
     ＮＨＫ総合\t1
     ＮＨＫ教育\t3
     日本テレビ\t4
     テレビ朝日\t5
     ＴＢＳテレビ\t6
     テレビ東京\t7
     フジテレビ\t8
     ＭＸテレビ\t9
     */
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray *filePaths = [NSMutableArray array];
    
    NSString *searchPath = [@"~/Downloads" stringByExpandingTildeInPath];
    NSString *outputName;
    NSArray *outputArray;
    [searchPath completePathIntoString:&outputName caseSensitive:NO matchesIntoArray:&outputArray filterTypes:[NSArray arrayWithObject:@"tvpi"]];
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
        program.station = [[program.station 
                            stringByReplacingOccurrencesOfString:@"SPTV" withString:@"CS"]
                           stringByReplacingOccurrencesOfString:@"BSDT" withString:@"BS"];
        program.memo    = [program.memo stringByReplacingOccurrencesOfString:@"<BR>" withString:@"\r\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, program.memo.length)];
        
        CalEvent *event = [CalEvent event];
        event.calendar  = calendar;
        event.title     = [NSString stringWithFormat:@"[%@] %@", program.station, program.title];
        event.startDate = program.startDateTime;
        event.endDate   = program.endDateTime;
        event.notes     = program.memo;
        
        NSError *error = nil;
        [calendarStore saveEvent:event span:CalSpanAllEvents error:&error];
        if (error != nil) {
            NSLog(@"%@", error);
        }
    }
    
    [pool drain];
    return 0;
}
