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


@end
