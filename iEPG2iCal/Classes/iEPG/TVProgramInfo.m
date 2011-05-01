//
//  TVProgramInfo.m
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 5/1/11.
//  Copyright 2011 sz50.com. All rights reserved.
//

#import "TVProgramInfo.h"


@implementation TVProgramInfo

static char CRLF[2] = {0xd, 0xa};

@synthesize dateTimeEnd;
@synthesize dateTimeStart;
@synthesize genre;
@synthesize memo;
@synthesize performer;
@synthesize programSubtitle;
@synthesize programTitle;
@synthesize station;
@synthesize subGenre;


#pragma -

+ (id)tvProgramInfoWithData:(NSData *)data {
    return [[[self alloc] initWithData:data] autorelease];
}

#pragma -

- (id)init {
    self = [super init];
    if (self) {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        encoding = NSASCIIStringEncoding;
    }
    
    return self;
}

- (id)initWithData:(NSData *)d {
    self = [self init];
    if (self) {
        data = [d retain];
        [self parse];
    }
    
    return self;
}


#pragma -

- (void)parse {
    NSData *CRLFData = [NSData dataWithBytes:CRLF length:2];
    BOOL headerPartEnds = NO;
    NSUInteger flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *dateComponentsStart = [calendar components:flags fromDate:[NSDate date]];
    NSDateComponents *dateComponentsEnd   = [calendar components:flags fromDate:[NSDate date]];
    NSUInteger cursor = 0;
    for (; cursor < data.length;) {
        NSRange range1 = [data rangeOfData:CRLFData options:0 range:NSMakeRange(cursor, data.length - cursor)];
        
        if (range1.location == NSNotFound) {
            break;
        }
        
        if (cursor == range1.location) {
            headerPartEnds = YES;
        }
        
        if (!headerPartEnds) {
            NSString *line = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(cursor, range1.location - cursor)] encoding:encoding] autorelease];
            NSRange range2 = [line rangeOfString:@":"];
            
            NSString *name = [[line substringToIndex:range2.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [[line substringFromIndex:range2.location + range2.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if ([name isCaseInsensitiveLike:@"content-type"]) {
                [self parseContentType:value];
                
            } else if ([name isCaseInsensitiveLike:@"version"]) {
                version = [value retain];
                
            } else if ([name isCaseInsensitiveLike:@"station"]) {
                self.station = value;
                
            } else if ([name isCaseInsensitiveLike:@"year"]) {
                [dateComponentsStart setYear:[value intValue]];
                [dateComponentsEnd setYear:[value intValue]];
                
            } else if ([name isCaseInsensitiveLike:@"month"]) {
                [dateComponentsStart setMonth:[value intValue]];
                [dateComponentsEnd setMonth:[value intValue]];
                
            } else if ([name isCaseInsensitiveLike:@"date"]) {
                [dateComponentsStart setDay:[value intValue]];
                [dateComponentsEnd setDay:[value intValue]];
                
            } else if ([name isCaseInsensitiveLike:@"start"]) {
                NSArray *array = [value componentsSeparatedByString:@":"];
                NSUInteger hour = [[array objectAtIndex:0] intValue];
                NSUInteger minute = [[array objectAtIndex:1] intValue];
                if (hour > 24) {
                    [dateComponentsStart setDay:dateComponentsStart.day + 1];
                    hour -= 24;
                }
                [dateComponentsStart setHour:hour];
                [dateComponentsStart setMinute:minute];
                
            } else if ([name isCaseInsensitiveLike:@"end"]) {
                NSArray *array = [value componentsSeparatedByString:@":"];
                NSUInteger hour = [[array objectAtIndex:0] intValue];
                NSUInteger minute = [[array objectAtIndex:1] intValue];
                if (hour > 24) {
                    [dateComponentsEnd setDay:dateComponentsEnd.day + 1];
                    hour -= 24;
                }
                [dateComponentsEnd setHour:hour];
                [dateComponentsEnd setMinute:minute];
                
            } else if ([name isCaseInsensitiveLike:@"program-title"]) {
                self.programTitle = value;
                
            } else if ([name isCaseInsensitiveLike:@"program-subtitle"]) {
                self.programSubtitle = value;
                
            } else if ([name isCaseInsensitiveLike:@"performer"]) {
                self.performer = value;
                
            } else if ([name isCaseInsensitiveLike:@"genre"]) {
                self.genre = [NSNumber numberWithInt:[value intValue]];
                
            } else if ([name isCaseInsensitiveLike:@"subgenre"]) {
                self.subGenre = [NSNumber numberWithInt:[value intValue]];
                
            }
        } else {
            cursor += CRLFData.length;
            self.memo = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(cursor, data.length - cursor)] encoding:encoding] autorelease];
            break;
        }
        cursor = range1.location + CRLFData.length;
    }
    
    self.dateTimeStart = [calendar dateFromComponents:dateComponentsStart];
    self.dateTimeEnd = [calendar dateFromComponents:dateComponentsEnd];
    if ([self.dateTimeStart compare:self.dateTimeEnd] == NSOrderedDescending) {
        self.dateTimeEnd = [self.dateTimeEnd dateByAddingTimeInterval:60 * 60 * 24];
    }
}

- (void)parseContentType:(NSString *)value {
    NSArray *components = [value componentsSeparatedByString:@";"];
    
    for (NSUInteger i = 0; i < components.count; i++) {
        if (i > 0) {
            NSString *s     = [components objectAtIndex:i];
            NSRange  range  = [s rangeOfString:@"="];
            NSString *name  = [[s substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [[s substringFromIndex:range.location + range.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if ([name isCaseInsensitiveLike:@"charset"]) {
                if ([value isCaseInsensitiveLike:@"UTF-8"]) {
                    encoding = NSUTF8StringEncoding;
                } else if ([value isCaseInsensitiveLike:@"Shift_JIS"]) {
                    encoding = NSShiftJISStringEncoding;
                }
            }
        }
    }
}


#pragma - 

- (NSString *)description {
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"{\n"];
    [s appendFormat:@"        version: %@\n", version];
    [s appendFormat:@"        station: %@\n", self.station];
    [s appendFormat:@"start date time: %@\n", self.dateTimeStart.description];
    [s appendFormat:@"  end date time: %@\n", self.dateTimeEnd.description];
    [s appendFormat:@"          title: %@\n", self.programTitle];
    [s appendFormat:@"       subtitle: %@\n", self.programSubtitle];
    [s appendFormat:@"      performer: %@\n", self.performer];
    [s appendFormat:@"          genre: %@ - %@\n", self.genre, self.subGenre];
    [s appendFormat:@"           memo: %@\n", self.memo];
    [s appendString:@"}\n"];
    return s;
}


#pragma - 

- (void)dealloc {
    [calendar release];
    [data release];
    [dateTimeEnd release];
    [dateTimeStart release];
    [genre release];
    [memo release];
    [performer release];
    [programSubtitle release];
    [programTitle release];
    [station release];
    [subGenre release];
    [version release];
    
    calendar        = nil;
    data            = nil;
    dateTimeEnd     = nil;
    dateTimeStart   = nil;
    genre           = nil;
    memo            = nil;
    performer       = nil;
    programSubtitle = nil;
    programTitle    = nil;
    station         = nil;
    subGenre        = nil;
    version         = nil;
    
    [super dealloc];
}

@end
