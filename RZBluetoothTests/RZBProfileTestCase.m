//
//  RZBProfileTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBProfileTestCase.h"
#import "XCTestCase+Helpers.h"

@implementation RZBProfileTestCase

- (void)waitForQueueFlush
{
    XCTestExpectation *e = [self expectationWithDescription:@"Queue Flush"];
    [self waitForDispatch:self.centralManager.dispatch expectation:e];
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Queue did not flush - %@", error);
        }
    }];
}


- (RZBMockCentralManager *)mockCentralManager
{
    return self.centralManager.mockCentralManager;
}

- (void)setUp
{
    [super setUp];
    self.centralManager = [[RZBTestableCentralManager alloc] init];
}

- (void)tearDown
{
    // All tests should end with no pending commands.
    RZBAssertCommandCount(0);
    self.centralManager = nil;
    [super tearDown];
}

@end
