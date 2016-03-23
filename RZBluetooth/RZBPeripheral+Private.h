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

- (instancetype)initWithCorePeripheral:(CBPeripheral *)corePeripheral
                        centralManager:(RZBCentralManager *)centralManager;

@property (weak, nonatomic, readonly) RZBCentralManager *centralManager;
@property (strong, nonatomic, readonly) CBPeripheral *corePeripheral;

@property (strong, nonatomic, readonly) NSMutableDictionary *notifyBlockByUUID;

- (RZBCharacteristicBlock)notifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID;
- (void)setNotifyBlock:(RZBCharacteristicBlock)notifyBlock forCharacteristicUUID:(CBUUID *)characteristicUUID;


@end
