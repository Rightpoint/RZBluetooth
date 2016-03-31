//
//  RZBPeripheral.m
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBPeripheral+Private.h"

@implementation RZBPeripheral

- (instancetype)initWithCorePeripheral:(CBPeripheral *)corePeripheral
                        centralManager:(RZBCentralManager *)centralManager;
{
    self = [super init];
    if (self) {
        _corePeripheral = corePeripheral;
        _centralManager = centralManager;
        _notifyBlockByUUID = [NSMutableDictionary dictionary];
        _corePeripheral.delegate = centralManager;
    }
    return self;
}

- (RZBCharacteristicBlock)notifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID
{
    return self.notifyBlockByUUID[characteristicUUID];
}

- (void)setNotifyBlock:(RZBCharacteristicBlock)notifyBlock forCharacteristicUUID:(CBUUID *)characteristicUUID;
{
    if (notifyBlock) {
        self.notifyBlockByUUID[characteristicUUID] = [notifyBlock copy];
    }
    else {
        [self.notifyBlockByUUID removeObjectForKey:characteristicUUID];
    }
}

- (NSString *)name
{
    return self.corePeripheral.name;
}

- (NSUUID *)identifier
{
    return self.corePeripheral.identifier;
}

- (CBPeripheralState)state
{
    return self.corePeripheral.state;
}

- (RZBCommandDispatch *)dispatch
{
    return self.centralManager.dispatch;
}

- (dispatch_queue_t)queue
{
    return self.centralManager.dispatch.queue;
}

- (void)setMaintainConnection:(BOOL)maintainConnection
{
    _maintainConnection = maintainConnection;
    if (maintainConnection) {
        [self.centralManager triggerAutomaticConnectionForPeripheral:self];
    }
}

- (void)readRSSI:(RZBRSSIBlock)completion
{
    NSParameterAssert(completion);
    RZBReadRSSICommand *cmd = [[RZBReadRSSICommand alloc] initWithUUIDPath:RZBUUIDP(self.identifier)];
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

- (void)cancelConnectionWithCompletion:(RZBErrorBlock)completion
{
    completion = completion ?: ^(NSError *error) {};
#warning More proof a delegate is the correct route.
    self.maintainConnection = NO;
    self.onConnection = nil;
    self.onDisconnection = nil;
    if (self.corePeripheral.state == CBPeripheralStateDisconnected) {
        dispatch_async(self.dispatch.queue, ^() {
            completion(nil);
        });
    }
    else {
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBCancelConnectionCommand class]
                                              matchingUUIDPath:RZBUUIDP(self.identifier)
                                                     createNew:YES];
        [cmd addCallbackBlock:^(id object, NSError *error) {
            completion(error);
        }];
        [self.dispatch dispatchCommand:cmd];
    }
}

- (void)connectWithCompletion:(RZBErrorBlock)completion
{
    completion = completion ?: ^(NSError *error) {};
    if (self.state == CBPeripheralStateConnected) {
        dispatch_async(self.dispatch.queue, ^() {
            completion(nil);
        });
    }
    else {
        // Add our callback to the current executing command
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBConnectCommand class]
                                              matchingUUIDPath:RZBUUIDP(self.identifier)
                                                     createNew:YES];
        [cmd addCallbackBlock:^(id object, NSError *error) {
            completion(error);
        }];
        [self.dispatch dispatchCommand:cmd];
    }
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

- (void)addObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                             serviceUUID:(CBUUID *)serviceUUID
                                onChange:(RZBCharacteristicBlock)onChange
                              completion:(RZBCharacteristicBlock)completion;
{
    NSParameterAssert(onChange);
    RZB_DEFAULT_BLOCK(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = YES;
    [cmd addCallbackBlock:^(CBCharacteristic *characteristic, NSError *error) {
        if (characteristic != nil) {
            [self setNotifyBlock:onChange forCharacteristicUUID:characteristic.UUID];
        }
        // REMOVE FOR NOW!!!
        //        if (//RZBExtensionShouldTriggerInitialValue &&
        //            characteristic.value && error == nil) {
        //            onChange(characteristic, nil);
        //        }
        completion(characteristic, error);
    }];
    [self.dispatch dispatchCommand:cmd];
}

- (void)removeObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                                serviceUUID:(CBUUID *)serviceUUID
                                 completion:(RZBCharacteristicBlock)completion;
{
    RZB_DEFAULT_BLOCK(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);

    // Remove the completion block immediately to behave consistently.
    // If anything here is nil, there is no completion block, which is fine.
    CBService *service = [self.centralManager serviceForUUID:serviceUUID onPeripheral:self.corePeripheral];
    CBCharacteristic *characteristic = [service rzb_characteristicForUUID:characteristicUUID];
    [self setNotifyBlock:nil forCharacteristicUUID:characteristic.UUID];

    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = NO;
    [cmd addCallbackBlock:^(CBCharacteristic *c, NSError *error) {
        completion(c, error);
    }];
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

- (void)discoverServiceUUIDs:(NSArray *)serviceUUIDs
                  completion:(RZBErrorBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier);
    RZBDiscoverServiceCommand *cmd = [[RZBDiscoverServiceCommand alloc] initWithUUIDPath:path];
    if (serviceUUIDs) {
        [cmd.serviceUUIDs addObjectsFromArray:serviceUUIDs];
    }
    [cmd addCallbackBlock:^(id object, NSError *error) {
        completion(error);
    }];
    [self.dispatch dispatchCommand:cmd];
}

- (void)discoverCharacteristicUUIDs:(NSArray *)characteristicUUIDs
                        serviceUUID:(CBUUID *)serviceUUID
                         completion:(RZBServiceBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID);
    RZBDiscoverCharacteristicCommand *cmd = [[RZBDiscoverCharacteristicCommand alloc] initWithUUIDPath:path];
    if (characteristicUUIDs) {
        [cmd.characteristicUUIDs addObjectsFromArray:characteristicUUIDs];
    }
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

@end
