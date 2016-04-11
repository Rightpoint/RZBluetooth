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

- (void)testSimulatedConnection
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

- (void)testSimulatedConnectionPaused
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
