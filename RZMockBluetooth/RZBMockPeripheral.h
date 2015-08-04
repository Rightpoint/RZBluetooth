//
//  RZBTestPeripheral.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RZBDefines.h"
@class RZBMockCentralManager;
@class RZBMockService;
@class RZBMockCharacteristic;
@protocol RZBMockPeripheralDelegate;

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

- (void)readRSSI;
- (void)discoverServices:(NSArray *)serviceUUIDs;
- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(RZBMockService *)service;
- (void)readValueForCharacteristic:(RZBMockCharacteristic *)characteristic;
- (void)writeValue:(NSData *)data forCharacteristic:(RZBMockCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(RZBMockCharacteristic *)characteristic;



- (RZBMockService *)serviceForUUID:(CBUUID *)serviceUUID;

- (RZBMockService *)newServiceForUUID:(CBUUID *)serviceUUID;

- (void)fakeRSSI:(NSNumber *)RSSI error:(NSError *)error;
- (void)fakeDiscoverService:(NSArray *)services error:(NSError *)error;
- (void)fakeDiscoverServicesWithUUIDs:(NSArray *)serviceUUIDs error:(NSError *)error;
- (void)fakeUpdateName:(NSString *)name;
- (void)fakeDiscoverCharacteristics:(NSArray *)services forService:(RZBMockService *)service error:(NSError *)error;
- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray *)serviceUUIDs forService:(RZBMockService *)service error:(NSError *)error;

- (void)fakeCharacteristic:(RZBMockCharacteristic *)characteristic updateValue:(NSData *)value error:(NSError *)error;
- (void)fakeCharacteristic:(RZBMockCharacteristic *)characteristic writeResponseWithError:(NSError *)error;
- (void)fakeCharacteristic:(RZBMockCharacteristic *)characteristic notify:(BOOL)notifyState error:(NSError *)error;

@end

@interface RZBMockPeripheral (Dynamic)

- (void)readCharacteristicUUID:(CBUUID *)characteristicUUID
                   serviceUUID:(CBUUID *)serviceUUID
                    completion:(RZBCharacteristicBlock)completion;
- (void)monitorCharacteristicUUID:(CBUUID *)characteristicUUID
                      serviceUUID:(CBUUID *)serviceUUID
                         onChange:(RZBCharacteristicBlock)onChange
                       completion:(RZBCharacteristicBlock)completion;
- (void)ignoreCharacteristicUUID:(CBUUID *)characteristicUUID
                     serviceUUID:(CBUUID *)serviceUUID
                      completion:(RZBCharacteristicBlock)completion;
- (void)writeData:(NSData *)data
characteristicUUID:(CBUUID *)characteristicUUID
      serviceUUID:(CBUUID *)serviceUUID;
- (void)writeData:(NSData *)data
characteristicUUID:(CBUUID *)characteristicUUID
      serviceUUID:(CBUUID *)serviceUUID
       completion:(RZBCharacteristicBlock)completion;

@end

@protocol RZBMockPeripheralDelegate <NSObject>

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(RZBMockService *)service;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(RZBMockCharacteristic *)characteristic;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(RZBMockCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(RZBMockCharacteristic *)characteristic;
- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)peripheral;

@end
