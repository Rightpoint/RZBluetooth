//
//  RZBMockedPeripheral.h
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@protocol RZBMockPeripheralDelegate;

@protocol RZBMockedPeripheral <NSObject>

@property(weak, nonatomic) id<RZBMockPeripheralDelegate> mockDelegate;
@property(assign) CBPeripheralState state;

- (void)fakeRSSI:(NSNumber *)RSSI error:(NSError *)error;
- (void)fakeDiscoverService:(NSArray *)services error:(NSError *)error;
- (void)fakeDiscoverServicesWithUUIDs:(NSArray *)serviceUUIDs error:(NSError *)error;
- (void)fakeUpdateName:(NSString *)name;
- (void)fakeDiscoverCharacteristics:(NSArray *)services forService:(CBMutableService *)service error:(NSError *)error;
- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray *)serviceUUIDs forService:(CBMutableService *)service error:(NSError *)error;

- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic updateValue:(NSData *)value error:(NSError *)error;
- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic writeResponseWithError:(NSError *)error;
- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic notify:(BOOL)notifyState error:(NSError *)error;

- (CBMutableService *)serviceForUUID:(CBUUID *)serviceUUID;

@end

@protocol RZBMockPeripheralDelegate <NSObject>

- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral discoverServices:(NSArray *)serviceUUIDs;
- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service;
- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral readValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;
- (void)mockPeripheralReadRSSI:(CBPeripheral<RZBMockedPeripheral> *)peripheral;

@end
