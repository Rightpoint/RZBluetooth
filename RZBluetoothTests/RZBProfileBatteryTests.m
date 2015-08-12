//
//  RZBProfileBatteryTests.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "CBPeripheral+RZBBattery.h"
#import "RZBSimulatedDevice+RZBBatteryLevel.h"


@interface RZBProfileBatteryTests : RZBSimulatedTestCase

@property (strong, nonatomic) CBMutableCharacteristic *batteryCharacteristic;
@end

@implementation RZBProfileBatteryTests

- (void)setUp
{
    [super setUp];
    [self.device addBatteryService];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRead
{
    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];

    self.device.batteryLevel = 80;
    [self.peripheral rzb_fetchBatteryLevel:^(NSUInteger level, NSError *error) {
        [read fulfill];
        XCTAssertNil(error);
        XCTAssert(level == 80);
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testMonitor
{
    XCTestExpectation *addMonitor = [self expectationWithDescription:@"Monitor battery level"];
    NSMutableArray *values = [NSMutableArray array];
    [self.peripheral rzb_addBatteryLevelObserver:^(NSUInteger level, NSError *error) {
        XCTAssertNil(error);
        [values addObject:@(level)];
    } completion:^(NSError *error) {
        XCTAssertNil(error);
        [addMonitor fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    NSArray *transmittedValues = @[@(10), @(20), @(30)];
    for (NSNumber *level in transmittedValues) {
        self.device.batteryLevel = [level unsignedIntegerValue];
        [self waitForQueueFlush];
    }
    XCTAssertEqualObjects(transmittedValues, values);
    [values removeAllObjects];
    XCTestExpectation *removeMonitor = [self expectationWithDescription:@"Monitor battery level"];

    [self.peripheral rzb_removeBatteryLevelObserver:^(NSError *error) {
        XCTAssertNil(error);
        [removeMonitor fulfill];
    }];
    self.device.batteryLevel = 33;
    [self waitForQueueFlush];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssert(values.count == 0);
}

@end
