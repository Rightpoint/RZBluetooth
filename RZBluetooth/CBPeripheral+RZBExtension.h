//
//  CBPeripheral+RZBExtension.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

@interface CBPeripheral (RZBExtension)

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
 * Monitor a characteristic for changes in value. The onChange block will be
 * triggered every time the characteristic changes.
 */
- (void)monitorCharacteristicUUID:(CBUUID *)characteristicUUID
                      serviceUUID:(CBUUID *)serviceUUID
                         onChange:(RZBCharacteristicBlock)onChange
                       completion:(RZBCharacteristicBlock)completion;

/**
 * Stop observing changes to the characteristic
 */
- (void)ignoreCharacteristicUUID:(CBUUID *)characteristicUUID
                     serviceUUID:(CBUUID *)serviceUUID
                      completion:(RZBCharacteristicBlock)completion;

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

@end
