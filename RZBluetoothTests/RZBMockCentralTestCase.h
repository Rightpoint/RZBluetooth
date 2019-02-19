//
//  RZBMockCentralTestCase.h
//  RZBluetooth
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import XCTest;

#import "RZBluetooth/RZBluetooth.h"
#import "RZBluetooth/RZMockBluetooth.h"

#import "RZBluetooth/RZBCommand.h"
#import "XCTestCase+Helpers.h"
#import "RZBluetooth/RZBCentralManager+Private.h"
#import "RZBInvocationLog.h"
#import "RZBTestDefines.h"

@interface RZBMockCentralTestCase : XCTestCase <RZBMockCentralManagerDelegate, RZBMockPeripheralDelegate>

@property (strong, nonatomic) RZBCentralManager *centralManager;
@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;
@property (strong, nonatomic) RZBInvocationLog *invocationLog;

- (void)ensureAndCompleteConnectionTo:(NSUUID *)peripheralUUID;
- (void)ensureAndCompleteDiscoveryOfService:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID;
- (void)ensureAndCompleteDiscoveryOfCharacteristic:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID;
- (void)setupConnectedPeripheral;
- (void)triggerThreeCommandsAndStoreErrorsIn:(NSMutableArray *)errors;

@end
