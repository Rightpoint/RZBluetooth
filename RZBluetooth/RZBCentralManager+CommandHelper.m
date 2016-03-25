//
//  RZBCentralManager+CommandHelper.m
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBCentralManager+CommandHelper.h"
#import "RZBPeripheral+Private.h"

@implementation RZBCentralManager (CommandHelper)

- (CBPeripheral *)connectedPeripheralForUUID:(NSUUID *)peripheralUUID
                          triggeredByCommand:(RZBCommand *)triggeringCommand
{
    NSParameterAssert(peripheralUUID);
    RZBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    BOOL connected = peripheral.state == CBPeripheralStateConnected;
    if (!connected) {
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBConnectCommand class]
                                              matchingUUIDPath:RZBUUIDP(peripheralUUID)
                                                     createNew:YES];
        triggeringCommand.retryAfter = cmd;
    }
    return connected ? peripheral.corePeripheral : nil;
}

- (CBService *)serviceForUUID:(CBUUID *)serviceUUID
                 onPeripheral:(CBPeripheral *)peripheral
           triggeredByCommand:(RZBCommand *)triggeringCommand;
{
    NSParameterAssert(serviceUUID);
    if (peripheral == nil) {
        return nil;
    }
    CBService *service = [self serviceForUUID:serviceUUID onPeripheral:peripheral];
    if (service == nil) {
        RZBDiscoverServiceCommand *cmd = [self.dispatch commandOfClass:[RZBDiscoverServiceCommand class]
                                                      matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                                                            isExecuted:NO
                                                             createNew:YES];
        [cmd addServiceUUID:serviceUUID];
        triggeringCommand.retryAfter = cmd;
    }
    return service;
}

- (CBCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID
                                  onService:(CBService *)service
                         triggeredByCommand:(RZBCommand *)triggeringCommand;
{
    NSParameterAssert(characteristicUUID);
    if (service == nil) {
        return nil;
    }
    CBCharacteristic *characteristic = [service rzb_characteristicForUUID:characteristicUUID];
    if (characteristic == nil) {
        CBPeripheral *peripheral = service.peripheral;
        NSParameterAssert(peripheral);
        RZBDiscoverCharacteristicCommand *cmd = [self.dispatch commandOfClass:[RZBDiscoverCharacteristicCommand class]
                                                             matchingUUIDPath:RZBUUIDP(peripheral.identifier, service.UUID)
                                                                   isExecuted:NO
                                                                    createNew:YES];
        [cmd addCharacteristicUUID:characteristicUUID];
        triggeringCommand.retryAfter = cmd;
    }
    return characteristic;
}

@end
