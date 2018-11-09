//
//  RZBPeripheral.m
//  RZBluetooth
//
//  Created by Brian King on 3/22/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBPeripheral+Private.h"
#import "RZBErrors.h"

@implementation RZBPeripheral

- (instancetype)initWithCorePeripheral:(CBPeripheral *)corePeripheral
                        centralManager:(RZBCentralManager *)centralManager;
{
    self = [super init];
    if (self) {
        _corePeripheral = corePeripheral;
        _centralManager = centralManager;
        _notifyBlockByUUIDs = [NSMutableDictionary dictionary];
        _corePeripheral.delegate = centralManager;
    }
    return self;
}

- (NSString *)keyForCharacteristicUUID:(CBUUID *)cuuid serviceUUID:(CBUUID *)suuid
{
    NSParameterAssert(cuuid);
    NSParameterAssert(suuid);
    return [NSString stringWithFormat:@"%@:%@", suuid.UUIDString, cuuid.UUIDString];
}

- (RZBCharacteristicBlock)notifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID
{
    NSString* key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    return self.notifyBlockByUUIDs[key];
}

- (void)setNotifyBlock:(RZBCharacteristicBlock)notifyBlock forCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID
{
    NSString* key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    if (notifyBlock) {
        self.notifyBlockByUUIDs[key] = [notifyBlock copy];
    }
    else {
        [self clearNotifyBlockForKey:key];
    }
}

- (void) clearNotifyBlockForKey:(NSString*) key {
    RZBCharacteristicBlock block = self.notifyBlockByUUIDs[key];
    [self.notifyBlockByUUIDs removeObjectForKey:key];
    if (block && self.notifyUnsubscription) {
        block(nil, [NSError errorWithDomain:RZBluetoothErrorDomain
                                       code:RZBluetoothNotifyUnsubscribed
                                   userInfo:nil]);
    }
}

- (void)clearNotifyBlocks {
    for (NSString* key in self.notifyBlockByUUIDs) {
        [self clearNotifyBlockForKey:key];
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

- (NSArray<CBService *> *)services
{
    return self.corePeripheral.services ?: @[];
}

- (RZBCommandDispatch *)dispatch
{
    return self.centralManager.dispatch;
}

- (dispatch_queue_t)queue
{
    return self.centralManager.dispatch.queue;
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
    self.maintainConnection = NO;
    [self cancelAllCommands];
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

- (void)cancelAllCommands
{
    NSError *error = [NSError errorWithDomain:RZBluetoothErrorDomain
                                         code:RZBluetoothConnectionCancelled
                                     userInfo:@{}];

    for (RZBCommand *command in [self.dispatch commands]) {
        [self.dispatch completeCommand:command
                            withObject:nil error:error];
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

- (void)enableNotifyForCharacteristicUUID:(CBUUID *)characteristicUUID
                              serviceUUID:(CBUUID *)serviceUUID
                                 onUpdate:(RZBCharacteristicBlock)onUpdate
                               completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(onUpdate);
    RZB_DEFAULT_BLOCK(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = YES;
    [cmd addCallbackBlock:^(CBCharacteristic *characteristic, NSError *error) {
        if (characteristic != nil) {
            [self setNotifyBlock:onUpdate forCharacteristicUUID:characteristic.UUID serviceUUID:serviceUUID];
        }
        completion(characteristic, error);
    }];
    [self.dispatch dispatchCommand:cmd];
}

- (void)clearNotifyBlockForCharacteristicUUID:(CBUUID *)characteristicUUID
                                  serviceUUID:(CBUUID *)serviceUUID
                                   completion:(RZBCharacteristicBlock)completion
{
    RZB_DEFAULT_BLOCK(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);

    // Remove the completion block immediately to behave consistently.
    // If anything here is nil, there is no completion block, which is fine.
    [self setNotifyBlock:nil forCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];

    // Disable the notify characteristic on the peripheral if the peripheral is
    // connected. If not connected, trigger completion.
    if (self.corePeripheral.state == CBPeripheralStateConnected) {
        RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
        cmd.notify = NO;
        [cmd addCallbackBlock:^(CBCharacteristic *c, NSError *error) {
            completion(c, error);
        }];
        [self.dispatch dispatchCommand:cmd];
    }
    else {
        dispatch_async(self.dispatch.queue, ^() {
            CBService *service = [self.corePeripheral rzb_serviceForUUID:serviceUUID];
            CBCharacteristic *characteristic = [service rzb_characteristicForUUID:characteristicUUID];
            completion(characteristic, nil);
        });
    }
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

- (void)connectionEvent:(RZBPeripheralStateEvent)event error:(NSError * __nullable)error;
{
    [self.connectionDelegate peripheral:self connectionEvent:event error:error];

    if (event != RZBPeripheralStateEventConnectSuccess && self.maintainConnection) {
        [self connectWithCompletion:nil];
    }
    
    if (self.connectionEventHandler) {
        self.connectionEventHandler(event, error);
    }
}

-(void)attemptReconnectionForEvent:(RZBPeripheralStateEvent)event {
    if (event != RZBPeripheralStateEventConnectSuccess && event != RZBPeripheralStateEventUserCancelled) {
        [self connectWithCompletion:nil];
    }
}

- (void)setMaintainConnection:(BOOL)maintainConnection
{
    _maintainConnection = maintainConnection;
    if (maintainConnection) {
        [self connectWithCompletion:nil];
    }
}

@end
