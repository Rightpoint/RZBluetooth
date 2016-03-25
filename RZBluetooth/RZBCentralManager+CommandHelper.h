//
//  RZBCentralManager+CommandHelper.h
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBCentralManager+Private.h"

@interface RZBCentralManager (CommandHelper)

/**
 * Obtain a connected peripheral. If the result is nil, a connect
 * command will be made, and the triggeredByCommand will be made dependent
 * on the connect command completing.
 */
- (CBPeripheral *)connectedPeripheralForUUID:(NSUUID *)peripheralUUID
                          triggeredByCommand:(RZBCommand *)triggeringCommand;

/**
 * Obtain a service. If the result is nil, a service discover
 * command will be made, and the triggeredByCommand will be made dependent
 * on the discover command completing.
 */
- (CBService *)serviceForUUID:(CBUUID *)serviceUUID
                 onPeripheral:(CBPeripheral *)peripheral
           triggeredByCommand:(RZBCommand *)triggeringCommand;

/**
 * Obtain a characteristic. If the result is nil, a characteristic discover
 * command will be made, and the triggeredByCommand will be made dependent
 * on the discover command completing.
 */
- (CBCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID
                                  onService:(CBService *)service
                         triggeredByCommand:(RZBCommand *)triggeringCommand;

@end
