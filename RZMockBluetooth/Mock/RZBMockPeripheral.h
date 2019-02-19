//
//  RZBMockPeripheral.h
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

@class RZBMockCentralManager;
@protocol RZBMockPeripheralDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * A fake peripheral object that behaves like a CBPeripheral.
 * This is not a subclass of CBPeripheral because of complications
 * of the CBPeripheral implementation. It will lookup instance methods
 * of CBPeripheral if the implementation is not in RZBMockPeripheral so
 * categories on CBPeripheral will transfer over.
 */
@interface RZBMockPeripheral : NSObject

@property(weak, nonatomic) RZBMockCentralManager *mockCentralManager;

@property(weak, nonatomic) id<CBPeripheralDelegate> delegate;
@property(weak, nonatomic) id<RZBMockPeripheralDelegate> mockDelegate;

@property(nonatomic) NSUUID *identifier;
@property(copy) NSString *name;
@property(assign) CBPeripheralState state;
@property(strong) NSArray *services;
@property(assign) NSUInteger fakeActionCount;
#if TARGET_OS_OSX
@property(strong) NSNumber *RSSI;
#endif

- (void)readRSSI;
- (void)discoverServices:(NSArray *)serviceUUIDs;
- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service;
- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;

- (CBMutableService *)serviceForUUID:(CBUUID *)serviceUUID;

- (CBMutableCharacteristic *)newServiceForUUID:(CBUUID *)serviceUUID;

- (void)fakeRSSI:(NSNumber *)RSSI error:(NSError *__nullable)error;
- (void)fakeDiscoverService:(NSArray<CBMutableService *> *)services error:(NSError *__nullable)error;
- (void)fakeDiscoverServicesWithUUIDs:(NSArray<CBUUID *> *)serviceUUIDs error:(NSError *__nullable)error;
- (void)fakeUpdateName:(NSString *)name;
- (void)fakeDiscoverCharacteristics:(NSArray<CBCharacteristic *> *)characteristics forService:(CBMutableService *)service error:(NSError *__nullable)error;
- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs forService:(CBMutableService *)service error:(NSError *__nullable)error;

- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic updateValue:(NSData *__nullable)value error:(NSError *__nullable)error;
- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic writeResponseWithError:(NSError *__nullable)error;
- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic notify:(BOOL)notifyState error:(NSError *__nullable)error;

@end

@protocol RZBMockPeripheralDelegate <NSObject>

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;
- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)peripheral;

@end

NS_ASSUME_NONNULL_END
