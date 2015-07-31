//
//  CBPeripheral+RZBExtension.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+RZBExtension.h"
#import "CBCharacteristic+RZBExtension.h"
#import "RZBCentralManager+Private.h"
#import "RZBUUIDPath.h"
#import "RZBCommand.h"

@implementation CBPeripheral (RZBExtension)

- (RZBCentralManager *)centralManager
{
    RZBCentralManager *centralManager = (id)self.delegate;
    NSAssert([centralManager isKindOfClass:[RZBCentralManager class]], @"CBPeripheral is not properly configured.  The delegate property must be configured to the RZCentralManager that owns it.");
    return centralManager;
}

- (RZBCommandDispatch *)dispatch
{
    return self.centralManager.dispatch;
}

- (void)readCharacteristicUUID:(CBUUID *)characteristicUUID
                   serviceUUID:(CBUUID *)serviceUUID
                    completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBReadCharacteristicCommand *cmd = [[RZBReadCharacteristicCommand alloc] initWithUUIDPath:path];
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

- (void)monitorCharacteristicUUID:(CBUUID *)characteristicUUID
                      serviceUUID:(CBUUID *)serviceUUID
                         onChange:(RZBCharacteristicBlock)onChange
                       completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(onChange);
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = YES;
    [cmd addCallbackBlock:^(CBCharacteristic *characteristic, NSError *error) {
        characteristic.notificationBlock = onChange;
        completion(characteristic, error);
    }];
    [self.dispatch dispatchCommand:cmd];
}

- (void)ignoreCharacteristicUUID:(CBUUID *)characteristicUUID
                     serviceUUID:(CBUUID *)serviceUUID
                      completion:(RZBCharacteristicBlock)completion
{
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = NO;
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

- (void)writeData:(NSData *)data
characteristicUUID:(CBUUID *)characteristicUUID
      serviceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(data);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBWriteCharacteristicCommand *cmd = [[RZBWriteCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.data = data;
    [self.dispatch dispatchCommand:cmd];
}

- (void)writeData:(NSData *)data
characteristicUUID:(CBUUID *)characteristicUUID
      serviceUUID:(CBUUID *)serviceUUID
       completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(data);
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBWriteCharacteristicCommand *cmd = [[RZBWriteWithReplyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.data = data;
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

@end
