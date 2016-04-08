//
//  RZBPeripheral.h
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBDefines.h"

@class RZBCentralManager, RZBPeripheral;

NS_ASSUME_NONNULL_BEGIN

@protocol RZBPeripheralConnectionDelegate <NSObject>

- (void)peripheral:(RZBPeripheral *)peripheral connectionEvent:(RZBPeripheralStateEvent)event error:(NSError *)error;

@end

@interface RZBPeripheral : NSObject

/**
 *  Designated initializer to over-ride by subclasses. You should not invoke this method directly.
 */
- (instancetype)initWithCorePeripheral:(CBPeripheral *)corePeripheral
                        centralManager:(RZBCentralManager *)centralManager NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  The identifier of the backing Core Bluetooth peripheral.
 */
@property (strong, nonatomic, readonly) NSUUID *identifier;

/**
 *  The name of the backing Core Bluetooth peripheral
 */
@property (retain, readonly, nullable) NSString *name;

/**
 *  The state of the backing Core Bluetooth peripheral.
 */
@property (nonatomic, readonly) CBPeripheralState state;

/**
 *  The service objects of the backing Core Bluetooth peripheral.
 */
@property (retain, readonly) NSArray<CBService *> *services;

/**
 * The dispatch queue that all callbacks occur on.
 */
@property (strong, nonatomic, readonly) dispatch_queue_t queue;

/**
 * Read the new RSSI value from the peripheral
 */
- (void)readRSSI:(RZBRSSIBlock)completion;

/**
 * Cancel the connection to a peripheral. This will cancel the connection
 * if connected. If the peripheral is not connected, it trigger the completion
 * block immediately. If the peripheral has a maintained connection, the
 * reconnect behavior will also be cancelled.
 */
- (void)cancelConnectionWithCompletion:(RZBErrorBlock __nullable)completion;

/**
 * Initiate a connection to a peripheral. This is exposed in case
 * someone wants to use it directly, but all of the above commands
 * will initiate a connection if needed, so this method is not needed.
 */
- (void)connectWithCompletion:(RZBErrorBlock __nullable)completion;

/**
 * Read a characteristic and trigger the completion block.
 *
 * @note if a read is performed on a characteristic that is notifying, the completion
 *       block will be triggered on the next value notification.
 */
- (void)readCharacteristicUUID:(CBUUID *)characteristicUUID
                   serviceUUID:(CBUUID *)serviceUUID
                    completion:(RZBCharacteristicBlock)completion;
/**
 * Add an observer to monitor a characteristic for changes in value. The onChange block will be
 * triggered every time the characteristic changes.
 *
 * @note if a value is already present for the characteristic, the onChange block will be triggered
 *       immediately. This will happen if the bluetooth service already has a cached value. If this
 *       behavior is not desired, call RZBShouldTriggerInitialValue(false)
 */
- (void)addObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                             serviceUUID:(CBUUID *)serviceUUID
                                onChange:(RZBCharacteristicBlock)onChange
                              completion:(RZBCharacteristicBlock __nullable)completion;

/**
 * Remove the observer monitoring the characteristic for changes in value. The onChange block
 * will be removed immediately apon invocation. The completion block will be triggered
 * once the peripheral has been notified that it no longer needs to send updates to this central.
 */
- (void)removeObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                                serviceUUID:(CBUUID *)serviceUUID
                                 completion:(RZBCharacteristicBlock __nullable)completion;



/**
 * Write the data to a specific characteristic.
 *
 * @param data The data to write to the characteristic.
 *
 * @note If the length of data is greater than the MTU Length (Default is 20bytes),
 *       CoreBluetooth will perform a staged write, which can have throughput
 *       implications.
 */
- (void)writeData:(NSData *)data
characteristicUUID:(CBUUID *)characteristicUUID
      serviceUUID:(CBUUID *)serviceUUID;

/**
 * Write the data to a specific characteristic and wait for a response from the
 * device. This is the same as the above command with a completion block.
 *
 * @note the completion block requires a notification from the device and may also
 *       impact throughput. It shouldn't be used unless required.
 */
- (void)writeData:(NSData *)data
characteristicUUID:(CBUUID *)characteristicUUID
      serviceUUID:(CBUUID *)serviceUUID
       completion:(RZBCharacteristicBlock)completion;

/**
 * Discover the services specified and trigger the completion block.
 *
 * @param serviceUUIDs array of services to discover. Pass nil to discover all services.
 * @param completion a completion block to trigger with the peripheral containing the specified services.
 *
 * @note this is not required to read or write, but can be used to discover if
 *       optional characteristics are available.
 *
 * @note the completion block will contain an error if the characteristics or
 *       services requested do not exist.
 */
- (void)discoverServiceUUIDs:(NSArray<CBUUID *> * __nullable)serviceUUIDs
                  completion:(RZBErrorBlock)completion;
/**
 * Discover the characteristics specified and trigger the completion block.
 *
 * @param characteristicUUIDs array of characteristic UUIDs to discover. Pass nil to discover all characteristics.
 * @param serviceUUID serviceUUID to discover the characteristics in.
 * @param completion a completion block to trigger with the peripheral containing the specified services.
 *
 * @note this is not required to read or write, but can be used to discover if
 *       optional characteristics are available.
 *
 * @note the completion block will contain an error if the characteristics or
 *       services requested do not exist.
 */
- (void)discoverCharacteristicUUIDs:(NSArray<CBUUID *> * __nullable)characteristicUUIDs
                        serviceUUID:(CBUUID *)serviceUUID
                         completion:(RZBServiceBlock)completion;

/**
 * The connectionDelegate is informed of RZBPeripheralStateEvents as they occur. This is
 * exposed by the delegate to allow for setup and tear down behavior specific to a certain
 * device.
 *
 * The connectionDelegate is always informed of connection errors after they are passed
 * to the completion blocks. For example if you are performing a characteristic read while
 * disconnected and there is a connection error, the connection error will be passed
 * to the completion block of the characteristic read, and then to the connectionDelegate.
 */
@property (weak, nonatomic) id<RZBPeripheralConnectionDelegate> connectionDelegate;

/**
 * This will make the central manager maintain a connection to this peripheral at
 * all times, reconnecting to the peripheral when the connection fails. This is
 * one of the most common patterns for connecting to a device with
 * battery limitations.
 *
 * If you have more complex connection requirements, use the onConnection and onDisconnection behavior.
 *
 * @note This bool is set to NO when cancelConnection is called.
 */
@property (nonatomic) BOOL maintainConnection;

/**
 * This method drives RZBPeripheralConnectionDelegate and the maintainConnection behavior.
 * This method is public in case a subclass intends to implement more nuanced connection
 * maintainence behavior.
 */
- (void)connectionEvent:(RZBPeripheralStateEvent)event error:(NSError * __nullable)error;

@end

NS_ASSUME_NONNULL_END
