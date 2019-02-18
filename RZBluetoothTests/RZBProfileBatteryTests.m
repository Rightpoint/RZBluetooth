//
//  RZBProfileBatteryTests.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"

@interface RZBProfileBatteryTests : RZBSimulatedTestCase

@end

@implementation RZBProfileBatteryTests

- (void)setUp
{
    [super setUp];
    [self.device addBatteryService];
    RZBSetLogHandler(^(RZBLogLevel logLevel, NSString *format, va_list args) {
        NSLog(@"%@", [[NSString alloc] initWithFormat:format arguments:args]);
    });
}

- (void)testRead
{
    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];

    self.device.batteryLevel = 80;
    [self.peripheral fetchBatteryLevel:^(NSUInteger level, NSError *error) {
        [read fulfill];
        XCTAssertNil(error);
        XCTAssert(level == 80);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testServiceDiscovery
{
    XCTestExpectation *discover = [self expectationWithDescription:@"Discover Battery Service"];

    self.device.batteryLevel = 80;
    [self.peripheral discoverServiceUUIDs:@[[CBUUID rzb_UUIDForBatteryService]] completion:^(NSError * _Nullable error) {
        [discover fulfill];
        XCTAssertNil(error);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testCharacteristicDiscovery
{
    XCTestExpectation *discover = [self expectationWithDescription:@"Discover Battery Service"];

    self.device.batteryLevel = 80;
    [self.peripheral discoverCharacteristicUUIDs:@[[CBUUID rzb_UUIDForBatteryLevelCharacteristic]] serviceUUID:[CBUUID rzb_UUIDForBatteryService] completion:^(CBService * _Nullable service, NSError * _Nullable error) {
        [discover fulfill];
        XCTAssertNil(error);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testMonitor
{
    XCTestExpectation *addMonitor = [self expectationWithDescription:@"Monitor battery level"];
    NSMutableArray *values = [NSMutableArray array];
    [self.peripheral addBatteryLevelObserver:^(NSUInteger level, NSError *error) {
        [values addObject:@(level)];
    } completion:^(NSError *error) {
        [addMonitor fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    NSArray *transmittedValues = @[@(10), @(20), @(30)];
    for (NSNumber *level in transmittedValues) {
        self.device.batteryLevel = [level unsignedIntegerValue];
        [self waitForQueueFlush];
    }
    XCTAssertEqualObjects(transmittedValues, values);
    [values removeAllObjects];
    XCTestExpectation *removeMonitor = [self expectationWithDescription:@"Monitor battery level"];

    [self.peripheral removeBatteryLevelObserver:^(NSError *error) {
        XCTAssertNil(error);
        [removeMonitor fulfill];
    }];
    self.device.batteryLevel = 33;
    [self waitForQueueFlush];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssert(values.count == 0);
}

@end
