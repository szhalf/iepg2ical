//
//  iEPG.h
//  iEPG2iCal
//
//  Created by SUZUKI, Wataru on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface iEPG : NSObject {
@private
    
}

+ (NSStringEncoding)detectEncoding:(NSData *)data;
+ (id)iEPGListWithContentOfFile:(NSString *)path;

- (id)initWithContentOfFile:(NSString *)path;
- (id)initWithData:(NSData *)data;


@end
