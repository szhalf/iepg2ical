//
//  iEPG.m
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 4/29/11.
//  Copyright 2011 sz50.com. All rights reserved.
//

#import "iEPG.h"
#import "TVProgramInfo.h"


@implementation iEPG

static char CRLF[2] = {0xd, 0xa};

@synthesize programInformations;


#pragma -

+ (id)iEPGWithData:(NSData *)data {
    return [[[self alloc] initWithData:data] autorelease];
}

+ (id)iEPGWithContentsOfFile:(NSString *)path {
    return [[[self alloc] initWithContentsOfFile:path] autorelease];
}


#pragma -

- (id)init {
    self = [super init];
    if (self) {
        programInformations = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithData:(NSData *)data {
    self = [self init];
    if (self) {
        sourceData = [data retain];
        [self parse];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path {
    return [self initWithData:[NSData dataWithContentsOfFile:path]];
}


#pragma -

- (void)parse {
    NSData *CRLFData  = [NSData dataWithBytes:CRLF length:2];
    
    // searching content mime type and boundary
    
    NSString         *contentType = nil;
    NSStringEncoding encoding     = NSASCIIStringEncoding;
    NSString         *boundary    = nil;
    NSUInteger       cursor       = 0;
    for (; cursor < sourceData.length;) {
        NSRange range1 = [sourceData rangeOfData:CRLFData options:0 range:NSMakeRange(cursor, sourceData.length - cursor)];
        
        if (range1.location == NSNotFound) {
            break;
        }
        
        if (cursor == range1.location) {
            cursor = range1.location + CRLFData.length;
            break;
        }
        
        NSData   *lineData = [sourceData subdataWithRange:NSMakeRange(cursor, range1.location - cursor)];
        NSString *line     = [[[NSString alloc] initWithData:lineData encoding:NSASCIIStringEncoding] autorelease];
        NSRange  range2    = [line rangeOfString:@":"];
        
        if (range2.location != NSNotFound) {
            NSString *name  = [line substringToIndex:range2.location];
            NSString *value = [line substringFromIndex:range2.location + range2.length];
            
            if ([name isCaseInsensitiveLike:@"content-type"]) {
                NSArray *components = [value componentsSeparatedByString:@";"];
                
                for (NSUInteger i = 0; i < components.count; i++) {
                    if (i == 0) {
                        contentType = [[components objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    } else {
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
            } else if ([name isCaseInsensitiveLike:@"boundary"]) {
                boundary = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
        }
        cursor = range1.location + CRLFData.length;
    }
    
    if (contentType == nil) {
        return;
    }
    
    if ([contentType isCaseInsensitiveLike:@"application/x-tv-program-info"]) {
        [programInformations addObject:[TVProgramInfo tvProgramInfoWithData:sourceData]];
    } else if ([contentType isCaseInsensitiveLike:@"application/x-multi-tv-program-info"]) {
        if (boundary == nil) {
            return;
        }
        NSMutableData *boundaryData = [NSMutableData dataWithData:CRLFData];
        [boundaryData appendData:[boundary dataUsingEncoding:encoding]];
        NSMutableData *terminatorData = [NSMutableData dataWithData:boundaryData];
        [terminatorData appendData:[@"--" dataUsingEncoding:encoding]];

        while (cursor < sourceData.length) {
            NSRange boundaryPosition = [sourceData rangeOfData:boundaryData options:0 range:NSMakeRange(cursor, sourceData.length - cursor)];
            NSRange terminatorPosition = [sourceData rangeOfData:terminatorData options:0 range:NSMakeRange(cursor, sourceData.length - cursor)];
     
            if (boundaryPosition.location == NSNotFound) {
                break;
            }
            if (cursor == boundaryPosition.location) {
                cursor = boundaryPosition.location + boundaryPosition.length + CRLFData.length;
                continue;
            }
            
            NSData *data = [sourceData subdataWithRange:NSMakeRange(cursor, boundaryPosition.location - cursor)];
            
            [programInformations addObject:[TVProgramInfo tvProgramInfoWithData:data]];
            
            if (boundaryPosition.location == terminatorPosition.location) {
                break;
            }
            cursor = boundaryPosition.location + boundaryPosition.length + CRLFData.length;
        }
    }
}


#pragma -

- (void)dealloc {
    [programInformations release];
    [sourceData release];
    
    programInformations = nil;
    sourceData          = nil;
    
    [super dealloc];
}

@end
