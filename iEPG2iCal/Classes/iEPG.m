//
//  iEPG.m
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iEPG.h"


@implementation iEPG

const char delimiter1[4] = {0xd, 0xa, 0xd, 0xa};

+ (NSStringEncoding)detectEncoding:(NSData *)data {
    NSRange range = [data rangeOfData:[NSData dataWithBytes:delimiter1 length:4] options:0 range:NSMakeRange(0, data.length)];
    NSString *header = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, range.location)] encoding:NSASCIIStringEncoding] autorelease];
    NSArray *headerList = [header componentsSeparatedByString:@"\r\n"];
    for (NSString *line in headerList) {
        NSArray *array = [line componentsSeparatedByString:@":"];
        NSString *headerName = [array objectAtIndex:0];
        if (![headerName isCaseInsensitiveLike:@"Content-Type"]) {
            continue;
        }
        NSString *headerValue = [array objectAtIndex:1];
        NSLog(@"%@ %@", headerName, headerValue);
    }
    
    return NSASCIIStringEncoding;    
}

+ (id)iEPGListWithContentOfFile:(NSString *)path {
    NSArray *iEPGList = [NSArray array];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    [self detectEncoding:data];
    
    //NSString *body = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(cursor + 4, data.length - cursor - 4)] encoding:NSShiftJISStringEncoding];
    
    //NSLog(@"%@", body);
    
    //NSLog(@"%@", [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, range.location)] encoding:NSShiftJISStringEncoding]);
    
    return iEPGList;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithContentOfFile:(NSString *)path {
    self = [self initWithData:[NSData dataWithContentsOfFile:path]];
    if (self) {
        
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    self = [self init];
    if (self) {
        
    }
    return data;
}

- (void)dealloc {
    [super dealloc];
}

@end
