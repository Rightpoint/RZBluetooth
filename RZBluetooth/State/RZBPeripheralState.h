//
//  RZBPeripheralState.h
//  RZBluetooth
//
//  Created by Brian King on 11/11/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;
#import "RZBDefines.h"

/**
 * Internal class to help manage callback state
 */
@interface RZBPeripheralState : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (copy, nonatomic) RZBPeripheralBlock onConnection;
@property (copy, nonatomic) RZBPeripheralBlock onDisconnection;
@property (assign, nonatomic) BOOL maintainConnection;

- (RZBCharacteristicBlock)notifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID;
- (void)setNotifyBlock:(RZBCharacteristicBlock)notifyBlock forCharacteristicUUID:(CBUUID *)characteristicUUID;

@end
