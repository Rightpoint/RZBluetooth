//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBBluetoothRepresentable.h"

@class RZBMockPeripheralManager;

NS_ASSUME_NONNULL_BEGIN

typedef CBATTError (^RZBATTRequestHandler)(CBATTRequest *request);
typedef void (^RZBNotificationHandler)(BOOL isNotifying);
typedef void (^RZBPeripheralManagerStateBlock)(CBPeripheralManagerState state);

/**
 *  The simulated device is a peripheral manager delegate that is intended to mock
 *  the behavior of real bluetooth device. This object can be used with both a real
 *  CBPeripheralManager class and an RZBMockPeripheralManager class. It is intended
 *  to be subclassed by clients of the library to implement all behavior specific to
 *  the device.
 */
@interface RZBSimulatedDevice : NSObject <CBPeripheralManagerDelegate>

/**
 *  Create a new device connected to a true CBPeripheralManager instance.
 *
 *  @param queue The dispatch queue to trigger the delegate on
 *  @param options The option dictionary to pass to the CBPeripheralManager
 */
- (instancetype)initWithQueue:(dispatch_queue_t __nullable)queue
                      options:(NSDictionary *)options;

/**
 *  The peripheralManager associated with this device. Note that this can be either a CBPeripheralManager
 *  or an API compatible RZBMockPeripheralManager, depending on how the simulated device was created.
 */
@property (strong, nonatomic, readonly) CBPeripheralManager *peripheralManager;

@property (strong, nonatomic, readonly) RZBMockPeripheralManager *mockPeripheralManager;

/**
 *  The dispatch queue passed to the constructor.
 */
@property (strong, nonatomic, readonly) dispatch_queue_t queue;

/**
 *  All of the services added to the peripheral
 */
@property (strong, nonatomic, readonly) NSArray<CBMutableService *> *services;

/**
 *  A block to be triggered on peripheral manager state change. When connecting to a real CBPeripheralManager
 *  services can only be configured when state is CBPeripheralManagerStatePoweredOn.
 */
@property (copy, nullable) RZBPeripheralManagerStateBlock onStateChange;

/**
 * Shared storage for categories. This is a hack that allows categories to define storage. I'm not sure
 * that it's the best approach, but it's there.
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *values;

/**
 *  The array of CBUUID's to include in the bluetooth advertisement.
 *
 *  @note This should be replaced by checking for isPrimary on the array of services.
 */
@property (strong, nonatomic, readonly) NSArray *advertisedServices;

/**
 *  Start advertising the device.
 */
- (void)startAdvertising;

/**
 *  Stop advertising the device.
 */
- (void)stopAdvertising;

/**
 *  Add a service to the device.
 */
- (void)addService:(CBMutableService *)service;

/**
 *  Block based API for adding read callback handlers for a characteristic with a specific UUID. Subclasses
 *  can also over-ride CBPeripheralManagerDelegate methods, as long as super is called.
 */
- (void)addReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBATTRequestHandler)handler;

/**
 *  Block based API for adding write callback handlers for a characteristic with a specific UUID. Subclasses
 *  can also over-ride CBPeripheralManagerDelegate methods, as long as super is called.
 */
- (void)addWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBATTRequestHandler)handler;

/**
 *  Block based API for adding subscribe callback handlers for a characteristic with a specific UUID. Subclasses
 *  can also over-ride CBPeripheralManagerDelegate methods, as long as super is called.
 */
- (void)addSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBNotificationHandler)handler;

/**
 *  Add a RZBBluetoothRepresentable object to the simulated device.
 */
- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary;

/**
 * Search all of the services for a characteristic matching characteristicUUID.
 */
- (CBMutableCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID;

@end

NS_ASSUME_NONNULL_END
