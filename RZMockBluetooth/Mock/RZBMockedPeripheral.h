//
//  RZBMockedPeripheral.h
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@protocol RZBMockPeripheralDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol RZBMockedPeripheral <NSObject>

@property(assign, nonatomic, nullable) id<CBPeripheralDelegate> delegate;
@property(retain, readonly, nullable) NSString *name;
@property(readonly) CBPeripheralState state;
@property(retain, readonly, nullable) NSArray<CBService *> *services;
- (void)readRSSI;
- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;
- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service;
- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;

@property(weak, nonatomic) id<RZBMockPeripheralDelegate> mockDelegate;

- (void)fakeRSSI:(NSNumber *)RSSI error:(NSError *__nullable)error;
- (void)fakeDiscoverService:(NSArray *)services error:(NSError *__nullable)error;
- (void)fakeDiscoverServicesWithUUIDs:(NSArray *)serviceUUIDs error:(NSError *__nullable)error;
- (void)fakeUpdateName:(NSString *)name;
- (void)fakeDiscoverCharacteristics:(NSArray *)services forService:(CBMutableService *)service error:(NSError *__nullable)error;
- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray *)serviceUUIDs forService:(CBMutableService *)service error:(NSError *__nullable)error;

- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic updateValue:(NSData *)value error:(NSError *__nullable)error;
- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic writeResponseWithError:(NSError *__nullable)error;
- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic notify:(BOOL)notifyState error:(NSError *__nullable)error;

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

NS_ASSUME_NONNULL_END
