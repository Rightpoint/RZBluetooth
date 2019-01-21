//
//  RZBPeripheralTests.m
//  RZBluetoothTests
//
//  Created by Josh Brown on 1/21/19.
//  Copyright © 2019 Raizlabs. All rights reserved.
//

@import XCTest;
#import "RZBSimulatedTestCase.h"
#import "RZBPeripheral+Private.h"
#import "CBUUID+TestUUIDs.h"

@interface RZBPeripheralTests : RZBSimulatedTestCase

@end

@implementation RZBPeripheralTests

- (void)testClearNotifyBlocks {
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.connection.identifier];
    
    [peripheral setNotifyBlock:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) { /* nothing to do */ }
         forCharacteristicUUID:[CBUUID cUUID]
                   serviceUUID:[CBUUID sUUID]];
    
    [peripheral setNotifyBlock:^(CBCharacteristic * _Nullable characteristic, NSError * _Nullable error) { /* nothing to do */ }
         forCharacteristicUUID:[CBUUID c2UUID]
                   serviceUUID:[CBUUID s2UUID]];

    XCTAssertNoThrow([peripheral clearNotifyBlocks]);
}

@end
