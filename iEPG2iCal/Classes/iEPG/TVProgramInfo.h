//
//  TVProgramInfo.h
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 5/1/11.
//  Copyright 2011 sz50.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TVProgramInfo : NSObject {
@private
    NSCalendar       *calendar;
    NSData           *data;
    NSDate           *dateTimeEnd;
    NSDate           *dateTimeStart;
    NSStringEncoding encoding;
    NSNumber         *genre;
    NSString         *memo;
    NSString         *performer;
    NSString         *programSubtitle;
    NSString         *programTitle;
    NSString         *station;
    NSNumber         *subGenre;
    NSString         *version;
}

+ (id)tvProgramInfoWithData:(NSData *)data;

- (id)initWithData:(NSData *)data;

- (void)parse;
- (void)parseContentType:(NSString *)value;

@property (nonatomic, retain) NSDate   *dateTimeEnd;
@property (nonatomic, retain) NSDate   *dateTimeStart;
@property (nonatomic, retain) NSNumber *genre;
@property (nonatomic, retain) NSString *memo;
@property (nonatomic, retain) NSString *performer;
@property (nonatomic, retain) NSString *programSubtitle;
@property (nonatomic, retain) NSString *programTitle;
@property (nonatomic, retain) NSString *station;
@property (nonatomic, retain) NSNumber *subGenre;

@end
