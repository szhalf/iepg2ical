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
    NSStringEncoding encoding;
    NSDate           *endDateTime;
    NSNumber         *genre;
    NSString         *memo;
    NSString         *performer;
    NSDate           *startDateTime;
    NSString         *station;
    NSNumber         *subGenre;
    NSString         *subtitle;
    NSString         *title;
    NSString         *version;
}

+ (id)tvProgramInfoWithData:(NSData *)data;

- (id)initWithData:(NSData *)data;

- (void)parse;
- (void)parseContentType:(NSString *)value;

@property (nonatomic, retain) NSDate   *endDateTime;
@property (nonatomic, retain) NSNumber *genre;
@property (nonatomic, retain) NSString *memo;
@property (nonatomic, retain) NSString *performer;
@property (nonatomic, retain) NSDate   *startDateTime;
@property (nonatomic, retain) NSString *station;
@property (nonatomic, retain) NSNumber *subGenre;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *title;

@end
