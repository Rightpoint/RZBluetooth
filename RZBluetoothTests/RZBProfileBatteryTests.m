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
@end

@implementation RZBProfileBatteryTests

- (void)setUp
{
    [super setUp];
    __weak typeof(self) welf = (id)self;
    CBMutableService *batteryService = [[CBMutableService alloc] initWithType:[CBUUID rzb_UUIDForBatteryService] primary:NO];
    batteryService.characteristics = @[
                                       [[CBMutableCharacteristic alloc] initWithType:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                                                          properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyIndicate
                                                                               value:nil permissions:CBAttributePermissionsReadable]
                                       ];
    [self.device.peripheralManager addService:batteryService];
    [self.device addReadCallbackForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                              handler:^CBATTError (CBATTRequest *request) {
                                                  uint8_t batteryLevel = welf.batteryLevel;
                                                  request.value = [NSData dataWithBytes:&batteryLevel length:1];
                                                  return CBATTErrorSuccess;
                                              }];
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

@end
