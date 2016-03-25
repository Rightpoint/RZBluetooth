//
//  RZBPeripheralManagerTests.m
//  RZBluetooth
//
//  Created by Brian King on 11/24/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "CBPeripheral+RZBBattery.h"
#import "RZBSimulatedDevice+RZBBatteryLevel.h"
#import "CBUUID+RZBPublic.h"
#import "XCTestCase+Helpers.h"

@interface RZBPeripheralManagerTests : RZBSimulatedTestCase

@property (assign, nonatomic) BOOL isNotifying;
@property (assign, nonatomic) NSUInteger level;

@end

@implementation RZBPeripheralManagerTests

- (void)setUp {
    [super setUp];
    typeof(self) welf = self;
    [self.device addBatteryService];
    [self.device addSubscribeCallbackForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic] handler:^(BOOL isNotifying) {
        welf.isNotifying = isNotifying;
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 * Confirm that the peripheral manager gets unsubscribe notifications when disconnected via disconnect
 */
- (void)testPeripheralManagerDisconnectionViaSimulatedConnectionDisconnection
{
    typeof(self) welf = self;
    [self.peripheral addBatteryLevelObserver:^(NSUInteger level, NSError *error) {
        welf.level = level;
    } completion:^(NSError *error) {
    }];
    [self waitForQueueFlush];
    XCTAssert(self.peripheral.state == CBPeripheralStateConnected);
    XCTAssert(self.isNotifying);

    self.connection.connectable = NO;
    [self waitForQueueFlush];
    XCTAssert(self.isNotifying == NO);
}

/**
 * Confirm that the peripheral manager gets unsubscribe notifications when disconnected cancel connection
 */
- (void)testPeripheralManagerDisconnectionViaCancelConnection
{
    typeof(self) welf = self;
    [self.peripheral addBatteryLevelObserver:^(NSUInteger level, NSError *error) {
        welf.level = level;
    } completion:^(NSError *error) {
    }];
    [self waitForQueueFlush];
    XCTAssert(self.peripheral.state == CBPeripheralStateConnected);
    XCTAssert(self.isNotifying);

    [self.peripheral cancelConnectionWithCompletion:^(NSError * _Nullable error) {
    }];
    [self waitForQueueFlush];
    XCTAssert(self.isNotifying == NO);
}

@end
