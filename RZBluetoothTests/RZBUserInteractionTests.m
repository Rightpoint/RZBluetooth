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
#import "RZBTestDefines.h"

static const NSTimeInterval DelayCausingTimeout = 1.0;

@interface RZBUserInteractionTests : RZBSimulatedTestCase

@end

@implementation RZBUserInteractionTests

- (void)setUp
{
    [RZBUserInteraction setTimeout:0.3];
    [super setUp];
    [self.device addBatteryService];
}

/**
 * This test will trigger all dependent commands and will not time out.
 */
- (void)testReadWithTimeoutNotTimingOut
{

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];

    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssertNil(error);
            XCTAssert(level == 80);
        }];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * This test will trigger a dependent connect command. The read will timeout and complete.
 */
- (void)testReadWithTimeoutTimingOut
{
    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.connection.readCharacteristicCallback.delay = DelayCausingTimeout;
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssert(error);
        }];
    }];
    [self waitForExpectationsWithTimeout:DelayCausingTimeout * 2 handler:nil];
}

/**
 * This test will trigger a dependent connect command. The read command will timeout and
 * this test ensures that both commands are completed.
 */
- (void)testReadWithConnectTimingOut
{
    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.connection.connectCallback.delay = DelayCausingTimeout;
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssert(error);
        }];
    }];
    [self waitForExpectationsWithTimeout:DelayCausingTimeout * 2 handler:nil];
}

/**
 *  This test will ensure that terminal states generate an error when using RZBUserInteraction
 */
- (void)testReadTerminalState
{
    [self.mockCentralManager fakeStateChange:CBManagerStatePoweredOff];
    [self waitForQueueFlush];

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssertNotNil(error);
            XCTAssert(error.code == RZBluetoothPoweredOff);
        }];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


/**
 *  This test will ensure that transient states generate an error after RZBUserInteraction timeout.
 */
- (void)testTimeoutNonFunctioningTransientState
{
    [self.mockCentralManager fakeStateChange:CBManagerStateUnknown];
    [self waitForQueueFlush];

    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];
    self.device.batteryLevel = 80;
    [RZBUserInteraction perform:^{
        [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
            [read fulfill];
            XCTAssert(error);
            XCTAssert(error.code == RZBluetoothTimeoutError);
        }];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
