//
//  XCTestCase+Helpers.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "XCTestCase+Helpers.h"
#import "RZBCommandDispatch.h"


@implementation XCTestCase (Helpers)

- (void)waitForQueueFlush
{
    XCTestExpectation *e = [self expectationWithDescription:@"Queue Flush"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [e fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
