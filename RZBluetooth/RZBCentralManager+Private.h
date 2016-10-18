//
//  RZCentralManager+Private.h
//  UMTSDK
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCentralManager.h"
#import "RZBCommandDispatch.h"

@interface RZBCentralManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic, readonly) RZBCommandDispatch *dispatch;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSUUID *, RZBPeripheral *> *peripheralsByUUID;
@property (strong, nonatomic, readonly) Class peripheralClass;

@property (nonatomic, copy) RZBScanBlock activeScanBlock;

- (CBService *)serviceForUUID:(CBUUID *)serviceUUID
                 onPeripheral:(CBPeripheral *)peripheral;

- (CBPeripheral *)corePeripheralForUUID:(NSUUID *)peripheralUUID;

@end
