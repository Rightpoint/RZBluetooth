//
//  RZBSimulationObjectTests.m
//  RZBluetooth
//
//  Created by Brian King on 4/11/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
@import CoreBluetooth;
#import "RZMockBluetooth.h"

@interface RZBSimulationObjectTests : XCTestCase

@end

@implementation RZBSimulationObjectTests

- (void)testSimulatedCallback
{
    __weak RZBSimulatedCallback *callback = nil;
    XCTestExpectation *exp = [self expectationWithDescription:@"Dispatch"];
    @autoreleasepool {
        callback = [RZBSimulatedCallback callbackOnQueue:dispatch_get_main_queue()];
        [callback dispatch:^(NSError * _Nullable injectedError) {
            XCTAssertNil(injectedError);
            [exp fulfill];
        }];
        [self waitForExpectationsWithTimeout:5 handler:nil];
    }
    XCTAssertNil(callback);
}

- (void)testSimulatedCallbackDelay
{
    __block NSUInteger dispatchCount = 0;
    RZBSimulatedCallback *callback = [RZBSimulatedCallback callbackOnQueue:dispatch_get_main_queue()];
    // Setup a callback, ensure it does not fire.
    callback.delay = 1.0;
    [callback dispatch:^(NSError * _Nullable injectedError) {
        dispatchCount += 1;
    }];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    XCTAssertEqual(dispatchCount, 0);
    // Add another callback a second from now
    [callback dispatch:^(NSError * _Nullable injectedError) {
        dispatchCount += 1;
    }];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
    XCTAssertEqual(dispatchCount, 1);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
    XCTAssertEqual(dispatchCount, 2);
    }

- (void)testSimulatedCallbackCancel
{
    __block BOOL dispatchFired = NO;
    RZBSimulatedCallback *callback = [RZBSimulatedCallback callbackOnQueue:dispatch_get_main_queue()];
    [callback dispatch:^(NSError * _Nullable injectedError) {
        XCTAssertNil(injectedError);
        dispatchFired = YES;
    }];
    [callback cancel];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssert(dispatchFired == NO);
}

- (void)testSimulatedCallbackPaused
{
    __weak RZBSimulatedCallback *callback = nil;
    __block BOOL triggered = NO;
    @autoreleasepool {
        callback = [RZBSimulatedCallback callbackOnQueue:dispatch_get_main_queue()];
        callback.paused = true;
        [callback dispatch:^(NSError * _Nullable injectedError) {
            XCTAssertNil(injectedError);
            triggered = YES;
        }];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        XCTAssertFalse(triggered);
    }
    XCTAssertNil(callback);
}

- (void)testSimulatedCentral
{
    NSUUID *device1 = [NSUUID UUID];
    NSUUID *device2 = [NSUUID UUID];
    RZBMockCentralManager *mockCentralManager = [[RZBMockCentralManager alloc] init];
    RZBSimulatedCentral *central = nil;
    __weak RZBSimulatedCentral *weakCentral = nil;
    @autoreleasepool {
        central = [[RZBSimulatedCentral alloc] initWithMockCentralManager:(id)mockCentralManager];
        [central addSimulatedDeviceWithIdentifier:device1
                                peripheralManager:(id)[[RZBMockPeripheralManager alloc] init]];
        [central addSimulatedDeviceWithIdentifier:device2
                                peripheralManager:(id)[[RZBMockPeripheralManager alloc] init]];

        XCTAssertNotNil([central connectionForIdentifier:device1]);
        XCTAssertNotNil([central connectionForIdentifier:device2]);
        // Nil out the strong storage to ensure there are no retain loops.
        weakCentral = central;
        central = nil;
    }
    XCTAssertNil(central);
}


@end
