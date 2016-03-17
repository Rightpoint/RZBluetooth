//
//  CBPeripheral+RZBExtension.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+Private.h"
#import "CBService+RZBExtension.h"
#import "RZBCentralManager+Private.h"
#import "RZBUUIDPath.h"
#import "RZBCommand.h"

@import ObjectiveC.runtime;

static BOOL RZBExtensionShouldTriggerInitialValue = YES;

@implementation CBPeripheral (RZBExtension)

- (RZBCommandDispatch *)rzb_dispatch
{
    return self.rzb_centralManager.dispatch;
}

- (RZBCentralManager *)rzb_centralManager
{
    RZBCentralManager *centralManager = (id)self.delegate;
    NSAssert([centralManager isKindOfClass:[RZBCentralManager class]], @"CBPeripheral is not properly configured.  The delegate property must be configured to the RZCentralManager that owns it.");
    return centralManager;
}

- (RZBPeripheralState *)rzb_peripheralState
{
    return [self.rzb_centralManager.managerState stateForIdentifier:self.identifier];
}

- (dispatch_queue_t)rzb_queue
{
    return self.rzb_centralManager.dispatch.queue;
}

- (void)rzb_readRSSI:(RZBRSSIBlock)completion
{
    NSParameterAssert(completion);
    RZBReadRSSICommand *cmd = [[RZBReadRSSICommand alloc] initWithUUIDPath:RZBUUIDP(self.identifier)];
    [cmd addCallbackBlock:completion];
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_readCharacteristicUUID:(CBUUID *)characteristicUUID
                       serviceUUID:(CBUUID *)serviceUUID
                        completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBReadCharacteristicCommand *cmd = [[RZBReadCharacteristicCommand alloc] initWithUUIDPath:path];
    [cmd addCallbackBlock:completion];
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_addObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                                 serviceUUID:(CBUUID *)serviceUUID
                                    onChange:(RZBCharacteristicBlock)onChange
                                  completion:(RZBCharacteristicBlock)completion;
{
    NSParameterAssert(onChange);
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = YES;
    [cmd addCallbackBlock:^(CBCharacteristic *characteristic, NSError *error) {
        if (characteristic != nil) {
            [self.rzb_peripheralState setNotifyBlock:onChange forCharacteristicUUID:characteristic.UUID];
        }
        if (RZBExtensionShouldTriggerInitialValue && characteristic.value && error == nil) {
            onChange(characteristic, nil);
        }
        completion(characteristic, error);
    }];
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_removeObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                                    serviceUUID:(CBUUID *)serviceUUID
                                     completion:(RZBCharacteristicBlock)completion;
{
    NSParameterAssert(characteristicUUID);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);

    // Remove the completion block immediately to behave consistently.
    // If anything here is nil, there is no completion block, which is fine.
    CBService *service = [self.rzb_centralManager serviceForUUID:serviceUUID onPeripheral:self];
    CBCharacteristic *characteristic = [service rzb_characteristicForUUID:characteristicUUID];
    [self.rzb_peripheralState setNotifyBlock:nil forCharacteristicUUID:characteristic.UUID];

    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = NO;
    [cmd addCallbackBlock:^(CBCharacteristic *c, NSError *error) {
        completion(c, error);
    }];
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_writeData:(NSData *)data
   characteristicUUID:(CBUUID *)characteristicUUID
          serviceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(data);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBWriteCharacteristicCommand *cmd = [[RZBWriteCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.data = data;
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_writeData:(NSData *)data
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
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_discoverServiceUUIDs:(NSArray *)serviceUUIDs
                      completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier);
    RZBDiscoverServiceCommand *cmd = [[RZBDiscoverServiceCommand alloc] initWithUUIDPath:path];
    if (serviceUUIDs) {
        [cmd.serviceUUIDs addObjectsFromArray:serviceUUIDs];
    }
    [cmd addCallbackBlock:completion];
    [self.rzb_dispatch dispatchCommand:cmd];
}

- (void)rzb_discoverCharacteristicUUIDs:(NSArray *)characteristicUUIDs
                            serviceUUID:(CBUUID *)serviceUUID
                             completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID);
    RZBDiscoverCharacteristicCommand *cmd = [[RZBDiscoverCharacteristicCommand alloc] initWithUUIDPath:path];
    if (characteristicUUIDs) {
        [cmd.characteristicUUIDs addObjectsFromArray:characteristicUUIDs];
    }
    [cmd addCallbackBlock:completion];
    [self.rzb_dispatch dispatchCommand:cmd];
}

@end

void RZBShouldTriggerInitialValue(BOOL notifyCachedValue)
{
    RZBExtensionShouldTriggerInitialValue = notifyCachedValue;
}

