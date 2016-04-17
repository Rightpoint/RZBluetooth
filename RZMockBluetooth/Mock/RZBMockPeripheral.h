//
//  RZBTestPeripheral.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"
#import "RZBMockedPeripheral.h"

@class RZBMockCentralManager;

/**
 * A fake peripheral object that behaves like a CBPeripheral.
 * This is not a subclass of CBPeripheral because of complications
 * of the CBPeripheral implementation. It will lookup instance methods
 * of CBPeripheral if the implementation is not in RZBMockPeripheral so
 * categories on CBPeripheral will transfer over.
 */
@interface RZBMockPeripheral : NSObject <RZBMockedPeripheral>

@property(weak, nonatomic) RZBMockCentralManager *mockCentralManager;

@property(weak, nonatomic) id<CBPeripheralDelegate> delegate;

@property(nonatomic) NSUUID *identifier;
@property() NSString *name;
@property(assign) CBPeripheralState state;
@property(strong) NSArray *services;

- (void)readRSSI;
- (void)discoverServices:(NSArray *)serviceUUIDs;
- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service;
- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;

- (CBMutableService *)serviceForUUID:(CBUUID *)serviceUUID;

- (CBMutableCharacteristic *)newServiceForUUID:(CBUUID *)serviceUUID;


@end

