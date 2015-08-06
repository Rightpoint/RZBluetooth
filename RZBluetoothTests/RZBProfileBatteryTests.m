//
//  RZBProfileBatteryTests.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "CBPeripheral+RZBBattery.h"

@interface RZBProfileBatteryTests : RZBSimulatedTestCase
@property (assign, nonatomic) uint8_t batteryLevel;
@property (strong, nonatomic) CBMutableCharacteristic *batteryCharacteristic;
@end

@implementation RZBProfileBatteryTests

- (void)setUp
{
    [super setUp];
    __weak typeof(self) welf = (id)self;
    CBMutableService *batteryService = [[CBMutableService alloc] initWithType:[CBUUID rzb_UUIDForBatteryService] primary:NO];
    self.batteryCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                                                    properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyIndicate
                                                                         value:nil permissions:CBAttributePermissionsReadable];
    batteryService.characteristics = @[self.batteryCharacteristic];

    [self.device.peripheralManager addService:batteryService];
    [self.device addReadCallbackForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                              handler:^CBATTError (CBATTRequest *request) {
                                                  uint8_t batteryLevel = welf.batteryLevel;
                                                  request.value = [NSData dataWithBytes:&batteryLevel length:1];
                                                  return CBATTErrorSuccess;
                                              }];
}

- (void)transmitValue:(uint8_t)level
{
    NSData *value = [NSData dataWithBytes:&level length:1];
    [self.device.peripheralManager updateValue:value
                             forCharacteristic:self.batteryCharacteristic
                          onSubscribedCentrals:nil];
    [self waitForQueueFlush];
}

- (void)tearDown
{
    self.batteryLevel = NSNotFound;
    [super tearDown];
}

- (void)testRead
{
    XCTestExpectation *read = [self expectationWithDescription:@"Read battery level"];

    self.batteryLevel = 80;
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
        [self transmitValue:[level unsignedIntegerValue]];
    }
    XCTAssertEqualObjects(transmittedValues, values);
    [values removeAllObjects];
    XCTestExpectation *removeMonitor = [self expectationWithDescription:@"Monitor battery level"];

    [self.peripheral rzb_removeBatteryLevelObserver:^(NSError *error) {
        XCTAssertNil(error);
        [removeMonitor fulfill];
    }];
    [self transmitValue:33];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssert(values.count == 0);
}

@end
