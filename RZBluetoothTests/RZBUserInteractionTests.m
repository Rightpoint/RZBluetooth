//
//  RZBUserInteractionTests.m
//  RZBluetooth
//
//  Created by Brian King on 11/10/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "RZBPeripheral+RZBBattery.h"
#import "RZBUserInteraction.h"
#import "RZBSimulatedDevice+RZBBatteryLevel.h"
#import "RZBErrors.h"

@interface RZBUserInteractionTests : RZBSimulatedTestCase

@end

@implementation RZBUserInteractionTests

- (void)setUp
{
    [super setUp];
    [self.device addBatteryService];
}

- (void)testReadWithTimeoutNotTimingOut
{
    [RZBUserInteraction setTimeout:0.1];

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];

    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssertNil(error);
            XCTAssert(level == 80);
        }];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testReadWithTimeoutTimingOut
{
    [RZBUserInteraction setTimeout:0.1];

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.connection.readCharacteristicCallback.delay = 1.0;
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssert(error);
        }];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testReadTerminalState
{
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOff];
    [self waitForQueueFlush];
    [RZBUserInteraction setTimeout:0.1];

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssert(error);
            XCTAssert(error.code == RZBluetoothPoweredOff);
        }];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testTimeoutNonFunctioningTransientState
{
    [self.mockCentralManager fakeStateChange:CBCentralManagerStateUnknown];
    [self waitForQueueFlush];
    [RZBUserInteraction setTimeout:0.1];

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssert(error);
            XCTAssert(error.code == RZBluetoothTimeoutError);
        }];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end
