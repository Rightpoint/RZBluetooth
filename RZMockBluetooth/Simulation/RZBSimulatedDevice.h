//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

@class RZBMockPeripheralManager;

typedef CBATTError (^RZBSimulatedDeviceRead)(CBATTRequest *request);
typedef void (^RZBSimulatedDeviceSubscribe)(BOOL isNotifying);

@interface RZBSimulatedDevice : NSObject <CBPeripheralManagerDelegate>

- (instancetype)initWithQueue:(dispatch_queue_t)queue options:(NSDictionary *)options peripheralManagerClass:(Class)peripheralManagerClass;

@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (strong, nonatomic, readonly) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic, readonly) dispatch_queue_t queue;
@property (strong, nonatomic, readonly) NSArray *services;

@property (copy, nonatomic) void (^onStateChange)(CBPeripheralManagerState);

/**
 * Shared storage for categories.
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *values;

- (void)addService:(CBMutableService *)service;
- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary;
- (void)addReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBSimulatedDeviceRead)handler;
- (void)addWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBSimulatedDeviceRead)handler;
- (void)addSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBSimulatedDeviceSubscribe)handler;

/**
 * Search all of the services for a characteristic matching characteristicUUID.
 */
- (CBMutableCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID;

@end
