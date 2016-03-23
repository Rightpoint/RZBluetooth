//
//  RZBPeripheral.h
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface RZBPeripheral : NSObject

/**
 * Read the new RSSI value from the peripheral
 */
- (void)readRSSI:(RZBRSSIBlock)completion;

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
                  completion:(RZBPeripheralBlock)completion;
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

@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (nonatomic, readonly) CBPeripheralState state;

@property (copy, nonatomic) RZBPeripheralBlock onConnection;
@property (copy, nonatomic) RZBPeripheralBlock onDisconnection;
@property (nonatomic) BOOL maintainConnection;
@property (strong, nonatomic) dispatch_queue_t queue;

@end

NS_ASSUME_NONNULL_END

#warning Add comments back
/**
 * This will make the central manager maintain a connection to the peripheral at
 * all times, reconnecting to the peripheral when the connection fails. This is
 * one of the most common patterns for connecting to a device with
 * battery limitations.
 *
 * This behavior will be disabled if cancelConnectionFromPeripheralUUID:completion: is called.
 *
 * @param peripheralUUID The UUID of the peripheral to connect to
 */
//- (void)maintainConnectionToPeripheralUUID:(NSUUID *)peripheralUUID;

/**
 * Specify a block to invoke when the peripheral with peripheralUUID is connected.
 *
 * This block will be cleared if cancelConnectionFromPeripheralUUID:completion: is called.
 *
 * @param peripheralUUID The UUID of the peripheral
 * @param onConnection The block to invoke on connection
 */
//- (void)setConnectionHandlerForPeripheralUUID:(NSUUID *)peripheralUUID
//handler:(RZBPeripheralBlock __nullable)onConnection;

/**
 * Specify a block to invoke when the peripheral with peripheralUUID is disconnected
 *
 * This block will be cleared if cancelConnectionFromPeripheralUUID:completion: is called.
 *
 * @param peripheralUUID The UUID of the peripheral
 * @param onDisconnection The block to invoke on connection
 */
//- (void)setDisconnectionHandlerForPeripheralUUID:(NSUUID *)peripheralUUID
//handler:(RZBPeripheralBlock __nullable)onDisconnection;
