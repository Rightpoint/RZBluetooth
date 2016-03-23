//
//  RZCentralManager.m
//  UMTSDK
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCentralManager+Private.h"
#import "CBService+RZBExtension.h"
#import "RZBPeripheral+Private.h"
#import "RZBCommandDispatch.h"
#import "RZBCommand.h"
#import "RZBUUIDPath.h"
#import "RZBErrors.h"
#import "RZBLog+Private.h"

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
#warning Check Threading Usage
        _peripheralsByUUID = [NSMutableDictionary dictionary];
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

- (void)cancelConnectionFromPeripheralUUID:(NSUUID *)peripheralUUID
                                completion:(RZBPeripheralBlock)completion
{
    NSParameterAssert(peripheralUUID);
    RZBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    if (peripheral.corePeripheral.state == CBPeripheralStateDisconnected) {
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
    RZBPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];

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

- (CBPeripheral *)corePeripheralForUUID:(NSUUID *)peripheralUUID
{
    NSParameterAssert(peripheralUUID);
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[peripheralUUID]];
    CBPeripheral *peripheral = [peripherals lastObject];
    peripheral.delegate = self;
    return peripheral;
}

- (RZBPeripheral *)peripheralForUUID:(NSUUID *)peripheralUUID
{
    NSParameterAssert(peripheralUUID);
    RZBPeripheral *peripheral = [self.peripheralsByUUID objectForKey:peripheralUUID];
    if (peripheral == nil) {
        CBPeripheral *corePeripheral = [self corePeripheralForUUID:peripheralUUID];
        peripheral = [[RZBPeripheral alloc] initWithCorePeripheral:corePeripheral
                                                    centralManager:self];
        [self.peripheralsByUUID setObject:peripheral forKey:peripheralUUID];
    }

    return peripheral;
}

- (RZBPeripheral *)peripheralForCorePeripheral:(CBPeripheral *)corePeripheral
{
    NSParameterAssert(corePeripheral);
    RZBPeripheral *peripheral = [self.peripheralsByUUID objectForKey:corePeripheral.identifier];
    if (peripheral == nil) {
        peripheral = [[RZBPeripheral alloc] initWithCorePeripheral:corePeripheral
                                                    centralManager:self];
        [self.peripheralsByUUID setObject:peripheral forKey:corePeripheral.identifier];
    }

    return peripheral;
}

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

- (void)triggerAutomaticConnectionForPeripheral:(RZBPeripheral *)peripheral
{
    if (peripheral.state == CBPeripheralStateDisconnected && peripheral.maintainConnection) {
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
    RZBLogDelegate(@"%@ - %@", NSStringFromSelector(_cmd), central);
    RZBLogDelegateValue(@"State=%d", (unsigned int)central.state);

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
    RZBLogDelegate(@"%@ - %@", NSStringFromSelector(_cmd), central);
    RZBLogDelegateValue(@"Restore State=%@", dict);

    NSMutableArray *peripherals = [NSMutableArray array];
    for (CBPeripheral *peripheral in dict[CBCentralManagerRestoredStatePeripheralsKey]) {
        peripheral.delegate = self;
        [peripherals addObject:[self peripheralForCorePeripheral:peripheral]];
    }
    if (self.restorationHandler) {
        self.restorationHandler(peripherals);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)corePeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral));
    RZBLogDelegateValue(@"advertisementData=%@", advertisementData);
    RZBLogDelegateValue(@"RSSI=%@", RSSI);

    if (self.activeScanBlock) {
        self.activeScanBlock([self peripheralForCorePeripheral:corePeripheral], advertisementData, RSSI);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)corePeripheral
{
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral));

    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];
    if (peripheral.onConnection) {
        peripheral.onConnection(peripheral, nil);
    }

    [self completeFirstCommandOfClass:[RZBConnectCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)corePeripheral error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral), error);
    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];

    [self completeFirstCommandOfClass:[RZBConnectCommand class]
                     matchingUUIDPath:RZBUUIDP(corePeripheral.identifier)
                           withObject:peripheral
                                error:error];
    [self triggerAutomaticConnectionForPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)corePeripheral error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral), error);
    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];

    if (peripheral.onDisconnection) {
        peripheral.onDisconnection(peripheral, error);
    }

#warning Ensure that we do not need to clear out the CBPeripheral storage here.
    
    [self completeFirstCommandOfClass:[RZBCancelConnectionCommand class]
                     matchingUUIDPath:RZBUUIDP(corePeripheral.identifier)
                           withObject:corePeripheral
                                error:error];

    // This delegate method can terminate any outstanding command, and is often the terminal event
    // for a connection. Fail all commands to this peripheral
    NSArray *commands = [self.dispatch commandsOfClass:nil
                                      matchingUUIDPath:RZBUUIDP(corePeripheral.identifier)
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
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(peripheral), error);
    RZBLogDelegateValue(@"RSSI=%@", RSSI);

    [self completeFirstCommandOfClass:[RZBReadRSSICommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:RSSI
                                error:error];
}

- (void)peripheral:(CBPeripheral *)corePeripheral didDiscoverServices:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(corePeripheral), error);
    RZBLogDelegateValue(@"Services=%@", RZBLogUUIDArray(corePeripheral.services));

    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];

    [self completeFirstCommandOfClass:[RZBDiscoverServiceCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:error];
}

- (void)peripheral:(CBPeripheral *)corePeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(corePeripheral), RZBLogUUID(service), error);
    RZBLogDelegateValue(@"Characteristics=%@", RZBLogUUIDArray(service.characteristics));

    [self completeFirstCommandOfClass:[RZBDiscoverCharacteristicCommand class]
                     matchingUUIDPath:RZBUUIDP(corePeripheral.identifier, service.UUID)
                           withObject:service
                                error:error];
}

- (void)peripheral:(CBPeripheral *)corePeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(corePeripheral), RZBLogUUID(characteristic), error);
    RZBLogDelegateValue(@"Value=%@", characteristic.value);

    RZBUUIDPath *path = RZBUUIDP(corePeripheral.identifier, characteristic.service.UUID, characteristic.UUID);
    BOOL complete = [self completeFirstCommandOfClass:[RZBReadCharacteristicCommand class]
                                     matchingUUIDPath:path
                                           withObject:characteristic
                                                error:error];

    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];
    RZBCharacteristicBlock notifyBlock = [peripheral notifyBlockForCharacteristicUUID:characteristic.UUID];

    if (!complete && characteristic.isNotifying && notifyBlock) {
        notifyBlock(characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)corePeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(corePeripheral), RZBLogUUID(characteristic), error);
    RZBUUIDPath *path = RZBUUIDP(corePeripheral.identifier, characteristic.service.UUID, characteristic.UUID);
    [self completeFirstCommandOfClass:[RZBWriteWithReplyCharacteristicCommand class]
                     matchingUUIDPath:path
                           withObject:characteristic
                                error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(peripheral), RZBLogUUID(characteristic), error);
    RZBLogDelegateValue(@"Notify=%@", characteristic.isNotifying ? @"YES" : @"NO");

    RZBUUIDPath *path = RZBUUIDP(peripheral.identifier, characteristic.service.UUID, characteristic.UUID);
    [self completeFirstCommandOfClass:[RZBNotifyCharacteristicCommand class]
                     matchingUUIDPath:path
                           withObject:characteristic
                                error:error];
}

@end
