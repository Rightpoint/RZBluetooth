//
//  XCTestCase+Helpers.m
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "XCTestCase+Helpers.h"
#import "RZBCommandDispatch.h"


@implementation XCTestCase (Helpers)

+ (NSUUID *)pUUID
{
    static NSUUID *UUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UUID = [NSUUID UUID];
    });
    return UUID;
}

+ (CBUUID *)sUUID
{
    return [CBUUID UUIDWithString:@"01234567"];
}

+ (CBUUID *)cUUID
{
    return [CBUUID UUIDWithString:@"12345678"];
}

+ (NSUUID *)p2UUID
{
    static NSUUID *UUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UUID = [NSUUID UUID];
    });
    return UUID;
}

+ (CBUUID *)s2UUID
{
    return [CBUUID UUIDWithString:@"23456701"];
}

+ (CBUUID *)c2UUID
{
    return [CBUUID UUIDWithString:@"23456789"];
}

+ (RZBUUIDPath *)pUUIDPath
{
    return RZBUUIDP(self.pUUID);
}

+ (RZBUUIDPath *)sUUIDPath
{
    return RZBUUIDP(self.pUUID, self.sUUID);
}

+ (RZBUUIDPath *)cUUIDPath
{
    return RZBUUIDP(self.pUUID, self.sUUID, self.cUUID);
}

- (void)waitForQueueFlush
{
    XCTestExpectation *e = [self expectationWithDescription:@"Queue Flush"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [e fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
