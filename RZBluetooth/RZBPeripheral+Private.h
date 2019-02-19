//
//  RZBPeripheral+Private.h
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBPeripheral.h"
#import "CBService+RZBExtension.h"
#import "RZBCentralManager+Private.h"
#import "RZBUUIDPath.h"
#import "RZBCommand.h"
#import "RZBDefines.h"

@interface RZBPeripheral ()

@property (weak, nonatomic, readonly) RZBCentralManager *centralManager;

@property (strong, nonatomic, readonly) NSMutableDictionary *notifyBlockByUUIDs;

- (NSString *)keyForCharacteristicUUID:(CBUUID *)cuuid serviceUUID:(CBUUID *)suuid;

- (RZBCharacteristicBlock)notifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID;
- (void)setNotifyBlock:(RZBCharacteristicBlock)notifyBlock forCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID;

- (void)clearNotifyBlocks;

@end

// CBPeripheral.identifier was moved to a base class with an availability restriction on it
// This clears the availability restriction so use of identifier does not generate
// a warning on mac.
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_13
@interface CBPeripheral (UUIDCompatibility)
- (NSUUID *)identifier;
@end
#else
#warning Remove a pre 10.13 warning fix.
#endif
