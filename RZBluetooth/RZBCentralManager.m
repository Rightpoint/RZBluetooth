//
//  RZCentralManager.m
//  UMTSDK
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCentralManager+Private.h"
#import "CBService+RZBExtension.h"
#import "CBPeripheral+RZBExtension.h"
#import "RZBCommandDispatch.h"
#import "RZBCommand.h"
#import "RZBUUIDPath.h"
#import "RZBErrors.h"

@implementation RZBCentralManager

- (instancetype)init
{
    return [self initWithIdentifier:@"com.raizlabs.bluetooth" queue:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier queue:(dispatch_queue_t)queue
{
    return [self initWithIdentifier:identifier queue:queue centralClass:[CBCentralManager class]];
}

- (instancetype)initWithIdentifier:(NSString *)identifier queue:(dispatch_queue_t)queue centralClass:(Class)centralClass
{
    NSParameterAssert(identifier);
    self = [super init];
    if (self) {
        NSDictionary *options = @{};
        _centralManager = [[centralClass alloc] initWithDelegate:self
                                                           queue:queue
                                                         options:options];
        _dispatch = [[RZBCommandDispatch alloc] initWithQueue:queue context:self];
        _managerState = [[RZBCentralManagerState alloc] init];
    }
    return self;
}

- (CBCentralManagerState)state
{
    return self.centralManager.state;
}

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs
                               options:(NSDictionary *)options
                onDiscoveredPeripheral:(RZBScanBlock)scanBlock
                               onError:(RZBErrorBlock)onError
{
    NSParameterAssert(scanBlock);
    self.activeScanBlock = scanBlock;
    [self completeScanCommand];
    RZBScanCommand *cmd = [self.dispatch commandOfClass:[RZBScanCommand class]
                                       matchingUUIDPath:nil
                                              createNew:YES];
    cmd.serviceUUIDs = serviceUUIDs;
    [cmd addCallbackBlock:^(id object, NSError *error) {
        if (onError && error) {
            onError(error);
        }
    }];

    [self.dispatch dispatchCommand:cmd];
}

- (void)stopScan
{
    self.activeScanBlock = nil;
    [self completeScanCommand];
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager stopScan];
    }
}

#pragma mark - Command Generation

- (void)maintainConnectionToPeripheralUUID:(NSUUID *)peripheralUUID
{
    NSParameterAssert(peripheralUUID);
    CBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    [self.managerState stateForIdentifier:peripheralUUID].maintainConnection = YES;
    [self triggerAutomaticConnectionForPeripheral:peripheral];
}

- (void)setConnectionHandlerForPeripheralUUID:(NSUUID *)peripheralUUID
                                      handler:(RZBPeripheralBlock)onConnection;
{
    [self.managerState stateForIdentifier:peripheralUUID].onConnection = onConnection;
}

- (void)setDisconnectionHandlerForPeripheralUUID:(NSUUID *)peripheralUUID
                                         handler:(RZBPeripheralBlock)onDisconnection;
{
    [self.managerState stateForIdentifier:peripheralUUID].onDisconnection = onDisconnection;
}

- (void)cancelConnectionFromPeripheralUUID:(NSUUID *)peripheralUUID
                                completion:(RZBPeripheralBlock)completion
{
    NSParameterAssert(peripheralUUID);
    CBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    [self.managerState stateForIdentifier:peripheralUUID].onConnection = nil;
    [self.managerState stateForIdentifier:peripheralUUID].onDisconnection = nil;
    [self.managerState stateForIdentifier:peripheralUUID].maintainConnection = NO;
    if (peripheral.state == CBPeripheralStateDisconnected) {
        dispatch_async(self.dispatch.queue, ^() {
            if (completion) {
                completion(peripheral, nil);
            }
        });
    }
    else {
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBCancelConnectionCommand class]
                                              matchingUUIDPath:RZBUUIDP(peripheralUUID)
                                                     createNew:YES];
        [cmd addCallbackBlock:completion];
        [self.dispatch dispatchCommand:cmd];
    }
}

- (void)connectToPeripheralUUID:(NSUUID *)peripheralUUID
                     completion:(RZBPeripheralBlock)completion
{
    NSParameterAssert(peripheralUUID);
    CBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    [self.managerState stateForIdentifier:peripheralUUID].peripheral = peripheral;
    if (peripheral.state == CBPeripheralStateConnected) {
        dispatch_async(self.dispatch.queue, ^() {
            if (completion) {
                completion(peripheral, nil);
            }
        });
    }
    else {
        // Add our callback to the current executing command
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBConnectCommand class]
                                              matchingUUIDPath:RZBUUIDP(peripheralUUID)
                                                     createNew:YES];
        [cmd addCallbackBlock:completion];
        [self.dispatch dispatchCommand:cmd];
    }
}

#pragma mark - Command Helpers

- (CBPeripheral *)peripheralForUUID:(NSUUID *)peripheralUUID
{
    NSParameterAssert(peripheralUUID);
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[peripheralUUID]];
    CBPeripheral *peripheral = [peripherals lastObject];
    peripheral.delegate = self;
    return peripheral;
}

- (CBPeripheral *)connectedPeripheralForUUID:(NSUUID *)peripheralUUID
                          triggeredByCommand:(RZBCommand *)triggeringCommand
{
    NSParameterAssert(peripheralUUID);
    CBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    BOOL connected = peripheral.state == CBPeripheralStateConnected;
    if (!connected) {
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBConnectCommand class]
                                              matchingUUIDPath:RZBUUIDP(peripheralUUID)
                                                     createNew:YES];
        triggeringCommand.retryAfter = cmd;
    }
    return connected ? peripheral : nil;
}

- (CBService *)serviceForUUID:(CBUUID *)serviceUUID onPeripheral:(CBPeripheral *)peripheral
{
    NSParameterAssert(serviceUUID);
    NSParameterAssert(peripheral);
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:serviceUUID]) {
            return service;
        }
    }
    return nil;
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

/**
 * Complete the first command matching the criteria with the specified objects.
 * If selector is not NULL, a warning will be printed if no matching command
 * is found.
 */
- (BOOL)completeFirstCommandOfClass:(Class)cls
                   matchingUUIDPath:(RZBUUIDPath *)UUIDPath
                         withObject:(id)object
                              error:(NSError *)error
{
    NSArray *commands = [self.dispatch commandsOfClass:cls matchingUUIDPath:UUIDPath isExecuted:YES];
    RZBCommand *command = commands.firstObject;
    [self.dispatch completeCommand:command withObject:object error:error];

    return commands.count > 0;
}

- (void)triggerAutomaticConnectionForPeripheral:(CBPeripheral *)peripheral;
{
    RZBPeripheralState *state = [self.managerState stateForIdentifier:peripheral.identifier];
    if (peripheral.state == CBPeripheralStateDisconnected && state.maintainConnection) {
        RZBConnectCommand *cmd = [self.dispatch commandOfClass:[RZBConnectCommand class]
                                              matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                                                     createNew:YES];
        [self.dispatch dispatchCommand:cmd];
    }
}

- (void)completeScanCommand
{
    RZBScanCommand *cmd = [self.dispatch commandOfClass:[RZBScanCommand class]
                                       matchingUUIDPath:nil
                                              createNew:NO];
    if (cmd) {
        [self.dispatch completeCommand:cmd withObject:nil error:nil];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (self.centralStateHandler) {
        self.centralStateHandler(central.state);
    }
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
            [self.dispatch resetCommands];
            break;
        case CBCentralManagerStatePoweredOn:
            [self.dispatch dispatchPendingCommands];
            break;
        default: {}
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    for (CBPeripheral *peripheral in peripherals) {
        peripheral.delegate = self;
        [self.managerState stateForIdentifier:peripheral.identifier].peripheral = peripheral;
    }
    if (self.restorationHandler) {
        self.restorationHandler(peripherals);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (self.activeScanBlock) {
        peripheral.delegate = self;
        self.activeScanBlock(peripheral, advertisementData, RSSI);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    RZBPeripheralBlock onConnection = [self.managerState stateForIdentifier:peripheral.identifier].onConnection;
    if (onConnection) {
        onConnection(peripheral, nil);
    }

    [self completeFirstCommandOfClass:[RZBConnectCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self completeFirstCommandOfClass:[RZBConnectCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:error];
    [self triggerAutomaticConnectionForPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    RZBPeripheralBlock onDisconnection = [self.managerState stateForIdentifier:peripheral.identifier].onDisconnection;
    if (onDisconnection) {
        onDisconnection(peripheral, error);
    }

    // Clear out the strong storage of the peripheral.
    [self.managerState stateForIdentifier:peripheral.identifier].peripheral = nil;

    [self completeFirstCommandOfClass:[RZBCancelConnectionCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:error];

    // This delegate method can terminate any outstanding command, and is often the terminal event
    // for a connection. Fail all commands to this peripheral
    NSArray *commands = [self.dispatch commandsOfClass:nil
                                      matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                                            isExecuted:YES];
    for (RZBCommand *command in commands) {
        [self.dispatch completeCommand:command withObject:nil error:error];
    }
    [self triggerAutomaticConnectionForPeripheral:peripheral];
}

#pragma mark CBPeripheralDelegate

//- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {}

// Nothing needs to be done here, everything will be re-discovered automatically
//- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    [self completeFirstCommandOfClass:[RZBReadRSSICommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:RSSI
                                error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    [self completeFirstCommandOfClass:[RZBDiscoverServiceCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    [self completeFirstCommandOfClass:[RZBDiscoverCharacteristicCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier, service.UUID)
                           withObject:service
                                error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    RZBUUIDPath *path = RZBUUIDP(peripheral.identifier, characteristic.service.UUID, characteristic.UUID);
    BOOL complete = [self completeFirstCommandOfClass:[RZBReadCharacteristicCommand class]
                                     matchingUUIDPath:path
                                           withObject:characteristic
                                                error:error];
    RZBCharacteristicBlock notifyBlock = [[self.managerState stateForIdentifier:peripheral.identifier] notifyBlockForCharacteristicUUID:characteristic.UUID];

    if (!complete && characteristic.isNotifying && notifyBlock) {
        notifyBlock(characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    RZBUUIDPath *path = RZBUUIDP(peripheral.identifier, characteristic.service.UUID, characteristic.UUID);
    [self completeFirstCommandOfClass:[RZBWriteWithReplyCharacteristicCommand class]
                     matchingUUIDPath:path
                           withObject:characteristic
                                error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    RZBUUIDPath *path = RZBUUIDP(peripheral.identifier, characteristic.service.UUID, characteristic.UUID);
    [self completeFirstCommandOfClass:[RZBNotifyCharacteristicCommand class]
                     matchingUUIDPath:path
                           withObject:characteristic
                                error:error];
}

@end
