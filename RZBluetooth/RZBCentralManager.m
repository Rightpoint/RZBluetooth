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
#import "RZBScanInfo.h"
#import "RZBLog+Private.h"
#import "RZBPeripheralStateEvent.h"
#import <TargetConditionals.h>

@implementation RZBCentralManager

+ (NSDictionary *)optionsForIdentifier:(NSString *)identifier
{
#if TARGET_OS_OSX
	return @{};
#elif TARGET_OS_IPHONE
    NSArray *backgroundModes = [[NSBundle mainBundle] infoDictionary][@"UIBackgroundModes"];

    BOOL backgroundSupport = [backgroundModes containsObject:@"bluetooth-central"];
    if (backgroundSupport == NO) {
        RZBLog(RZBLogLevelConfiguration, @"Background central support is not enabled. Add 'bluetooth-central' to UIBackgroundModes to enable background support");
    }
    return backgroundSupport ? @{CBCentralManagerOptionRestoreIdentifierKey: identifier} : @{};
#else
	#warning Unsupported Platform
#endif
}

- (instancetype)init
{
    return [self initWithIdentifier:@"com.raizlabs.bluetooth" queue:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier queue:(dispatch_queue_t)queue
{
    return [self initWithIdentifier:identifier peripheralClass:[RZBPeripheral class] queue:queue];
}

- (instancetype)initWithIdentifier:(NSString *)identifier peripheralClass:(Class)peripheralClass queue:(dispatch_queue_t __nullable)queue;
{
    NSParameterAssert(identifier);
    self = [super init];
    if (self) {
        _peripheralClass = peripheralClass ?: [RZBPeripheral class];
        NSDictionary *options = [self.class optionsForIdentifier:identifier];
        _coreCentralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:queue
                                                                 options:options];
        _dispatch = [[RZBCommandDispatch alloc] initWithQueue:queue context:self];
        _peripheralsByUUID = [NSMutableDictionary dictionary];
    }
    return self;
}

- (CBManagerState)state
{
    return self.coreCentralManager.state;
}

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs
                               options:(NSDictionary *)options
                onDiscoveredPeripheral:(RZBScanBlock)scanBlock
{
    NSParameterAssert(scanBlock);
    self.activeScanBlock = scanBlock;
    [self completeScanCommand];
    RZBScanCommand *cmd = [self.dispatch commandOfClass:[RZBScanCommand class]
                                       matchingUUIDPath:nil
                                              createNew:YES];
    cmd.serviceUUIDs = serviceUUIDs;
    cmd.scanOptions = options;
    [cmd addCallbackBlock:^(id object, NSError *error) {
        if (error) {
            scanBlock(nil, error);
        }
    }];

    [self.dispatch dispatchCommand:cmd];
}

- (void)stopScan
{
    self.activeScanBlock = nil;
    [self completeScanCommand];
    if (self.coreCentralManager.state == CBManagerStatePoweredOn) {
        [self.coreCentralManager stopScan];
    }
}

- (NSArray<RZBPeripheral *> *)retrieveConnectedPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs
{
    NSMutableArray<RZBPeripheral *> *result = [NSMutableArray array];
    NSArray<CBPeripheral *> *connectedPeripherals = [self.coreCentralManager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
    for (CBPeripheral *p in connectedPeripherals) {
        [result addObject:[self peripheralForCorePeripheral:p]];
    }
    return result;
}

#pragma mark - Lookup Helpers

- (CBPeripheral *)corePeripheralForUUID:(NSUUID *)peripheralUUID
{
    NSParameterAssert(peripheralUUID);
    NSArray *peripherals = [self.coreCentralManager retrievePeripheralsWithIdentifiers:@[peripheralUUID]];
    CBPeripheral *peripheral = [peripherals lastObject];
    peripheral.delegate = self;
    return peripheral;
}

- (RZBPeripheral *)peripheralForCorePeripheral:(CBPeripheral *)corePeripheral
{
    NSParameterAssert(corePeripheral);
    RZBPeripheral *peripheral = [self.peripheralsByUUID objectForKey:corePeripheral.identifier];
    if (peripheral == nil) {
        peripheral = [[self.peripheralClass alloc] initWithCorePeripheral:corePeripheral
                                                           centralManager:self];
        [self.peripheralsByUUID setObject:peripheral forKey:corePeripheral.identifier];
    }

    return peripheral;
}

- (RZBPeripheral *)peripheralForUUID:(NSUUID *)peripheralUUID
{
    NSParameterAssert(peripheralUUID);
    RZBPeripheral *peripheral = [self.peripheralsByUUID objectForKey:peripheralUUID];
    if (peripheral == nil) {
        CBPeripheral *corePeripheral = [self corePeripheralForUUID:peripheralUUID];
        peripheral = [[self.peripheralClass alloc] initWithCorePeripheral:corePeripheral
                                                           centralManager:self];
        [self.peripheralsByUUID setObject:peripheral forKey:peripheralUUID];
    }

    return peripheral;
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
    RZBCommand *cmd = commands.firstObject;
    if (cmd) {
        [self.dispatch completeCommand:cmd withObject:object error:error];
    }

    return commands.count > 0;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:RZBCentralManagerStateChangeNotification
                                                        object:self];
    if (self.centralStateHandler) {
        self.centralStateHandler(central.state);
    }
    switch (central.state) {
        case CBManagerStateUnknown:
        case CBManagerStateResetting:
            // These are intermittent states that will have caused any outstanding
            // commands to not respond. Reset the commands so when the state is
            // known the commands are retried
            [self.dispatch resetCommands];
            break;
        case CBManagerStateUnsupported:
        case CBManagerStateUnauthorized:
        case CBManagerStatePoweredOff:
            // Reset the commands so when they are dispatched again, they will
            // generate an error message.
            [self.dispatch resetCommands];
            [self.dispatch dispatchPendingCommands];
            break;
        case CBManagerStatePoweredOn:
            [self.dispatch dispatchPendingCommands];
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
#if TARGET_OS_IPHONE
    RZBLogDelegate(@"%@ - %@", NSStringFromSelector(_cmd), central);
    RZBLogDelegateValue(@"Restore State=%@", dict);

    NSMutableArray *peripherals = [NSMutableArray array];
    for (CBPeripheral *peripheral in dict[CBCentralManagerRestoredStatePeripheralsKey]) {
        peripheral.delegate = self;
        [peripherals addObject:[self peripheralForCorePeripheral:peripheral]];
    }
    NSDictionary *userInfo = @{RZBCentralManagerPeripheralKey: peripherals};
    [[NSNotificationCenter defaultCenter] postNotificationName:RZBCentralManagerRestorePeripheralNotification
                                                        object:self
                                                      userInfo:userInfo];
    if (self.restorationHandler) {
        self.restorationHandler(peripherals);
    }
#endif
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)corePeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral));
    RZBLogDelegateValue(@"advertisementData=%@", advertisementData);
    RZBLogDelegateValue(@"RSSI=%@", RSSI);

    if (self.activeScanBlock) {
        RZBScanInfo *scanInfo = [[RZBScanInfo alloc] init];
        scanInfo.RSSI = RSSI;
        scanInfo.advInfo = advertisementData;
        scanInfo.peripheral = [self peripheralForCorePeripheral:corePeripheral];
        self.activeScanBlock(scanInfo, nil);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)corePeripheral
{
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral));
    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];

    [self completeFirstCommandOfClass:[RZBConnectCommand class]
                     matchingUUIDPath:RZBUUIDP(peripheral.identifier)
                           withObject:peripheral
                                error:nil];
    [peripheral connectionEvent:RZBPeripheralStateEventConnectSuccess error:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)corePeripheral error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral), error);
    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];

    [self completeFirstCommandOfClass:[RZBConnectCommand class]
                     matchingUUIDPath:RZBUUIDP(corePeripheral.identifier)
                           withObject:peripheral
                                error:error];
    [peripheral connectionEvent:RZBPeripheralStateEventConnectFailure error:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)corePeripheral error:(NSError *)error
{
    RZBLogDelegate(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), central, RZBLogIdentifier(corePeripheral), error);
    RZBPeripheral *peripheral = [self peripheralForCorePeripheral:corePeripheral];

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
    // Clear out any onUpdate blocks
    [peripheral.notifyBlockByUUIDs removeAllObjects];
    [peripheral connectionEvent:RZBPeripheralStateEventDisconnected error:error];
}

#pragma mark CBPeripheralDelegate

//- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {}

// Nothing needs to be done here, everything will be re-discovered automatically. Send the event to the log system.
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
    RZBLogDelegate(@"%@ - %@ %@", NSStringFromSelector(_cmd), RZBLogIdentifier(peripheral), invalidatedServices);
}

#if TARGET_OS_OSX
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSNumber *RSSI = [peripheral RSSI];
#else
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
#endif

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
    RZBCharacteristicBlock notifyBlock = [peripheral notifyBlockForCharacteristicUUID:characteristic.UUID serviceUUID:characteristic.service.UUID];

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

NSString *const RZBCentralManagerStateChangeNotification = @"RZBCentralManagerStateChangeNotification";
NSString *const RZBCentralManagerRestorePeripheralNotification  = @"RZBCentralManagerRestorePeripheralNotification";
NSString *const RZBCentralManagerPeripheralKey  = @"RZBCentralManagerPeripheralKey";
