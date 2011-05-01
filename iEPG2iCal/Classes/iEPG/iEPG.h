//
//  iEPG.h
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 4/29/11.
//  Copyright 2011 sz50.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface iEPG : NSObject {
@private
    NSMutableArray *programInformations;
    NSData         *sourceData;
}

+ (id)iEPGWithData:(NSData *)data;
+ (id)iEPGWithContentsOfFile:(NSString *)path;

- (id)initWithData:(NSData *)data;
- (id)initWithContentsOfFile:(NSString *)path;

- (void)parse;

@property (nonatomic, readonly) NSArray *programInformations;

@end
