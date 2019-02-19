//
//  RZBSimulatedDevice.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedConnection+Private.h"
#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedCallback.h"
#import "RZBSimulatedCentral.h"
#import "RZBLog+Private.h"

@implementation RZBSimulatedConnection

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                    peripheralName:(NSString *)peripheralName
                 peripheralManager:(RZBMockPeripheralManager *)peripheralManager
                           central:(RZBSimulatedCentral *)central
{
    NSParameterAssert(identifier);
    NSParameterAssert(peripheralManager);
    NSParameterAssert(central);
    self = [super init];
    if (self) {
        _identifier = identifier;
        _central = central;
        _peripheralManager = peripheralManager;
        _peripheralManager.mockDelegate = self;
        _peripheral = [central.mockCentralManager peripheralForUUID:identifier];
        _peripheral.name = peripheralName;
        _readRequests = [NSMutableArray array];
        _writeRequests = [NSMutableArray array];
        _subscribedCharacteristics = [NSMutableArray array];
        _staticCharacteristicValues = [NSMutableDictionary dictionary];

        self.scanCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.scanCallback.paused = YES;
        self.connectCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.cancelConncetionCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.readRSSICallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.discoverServiceCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.discoverCharacteristicCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.readCharacteristicCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.writeCharacteristicCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.notifyCharacteristicCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.requestCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
        self.updateCallback = [RZBSimulatedCallback callbackOnQueue:central.mockCentralManager.queue];
    }
    return self;
}

- (BOOL)isDiscoverableWithServices:(NSArray *)services
{
    BOOL discoverable = (services == nil);
    for (CBService *service in self.peripheralManager.services) {
        if (service.isPrimary && [services containsObject:service.UUID]) {
            discoverable = YES;
        }
    }
    return discoverable;
}

- (void)setConnectable:(BOOL)connectable
{
    self.connectCallback.paused = !connectable;
    _connectable = connectable;
    if (connectable == NO) {
        if (self.peripheral.state == CBPeripheralStateConnected
#if TARGET_OS_IOS
            || self.peripheral.state == CBPeripheralStateConnecting
#endif
            ) {
            [self disconnect];
        }
    }
}

- (void)disconnect
{
    for (RZBSimulatedCallback *callback in self.connectionDependentCallbacks) {
        [callback cancel];
    }
    for (CBMutableCharacteristic *characteristic in self.subscribedCharacteristics) {
        [self.peripheralManager fakeNotifyState:NO central:(id)self.central characteristic:characteristic];
    }
    [self.subscribedCharacteristics removeAllObjects];
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_9_0
    self.peripheral.state = CBPeripheralStateDisconnecting;
#endif
    typeof(self) weakSelf = self;
    [self.cancelConncetionCallback dispatch:^(NSError *injectedError) {
        [weakSelf.central.mockCentralManager fakeDisconnectPeripheralWithUUID:weakSelf.identifier
                                                                        error:injectedError];
    }];
}

- (void)reset
{
    for (RZBSimulatedCallback *callback in self.allCallbacks) {
        [callback cancel];
    }
    self.peripheral.state = CBPeripheralStateDisconnected;
    self.peripheral.services = @[];
}

- (BOOL)idle
{
    BOOL idle = YES;
    for (RZBSimulatedCallback *callback in self.allCallbacks) {
        if (callback.paused == NO && callback.idle == NO) {
            idle = NO;
        }
    }
    if (self.peripheral.fakeActionCount > 0) {
        idle = NO;
    }
    else if (self.peripheralManager.fakeActionCount > 0) {
        idle = NO;
    }
    return idle;
}

- (NSArray *)allCallbacks
{
    NSMutableArray *allCallbacks = [self.connectionDependentCallbacks mutableCopy];
    [allCallbacks addObject:self.scanCallback];
    [allCallbacks addObject:self.cancelConncetionCallback];
    return allCallbacks;
}

- (NSArray *)connectionDependentCallbacks
{
    return @[self.connectCallback,
             self.discoverServiceCallback,
             self.discoverCharacteristicCallback,
             self.readRSSICallback,
             self.readCharacteristicCallback,
             self.writeCharacteristicCallback,
             self.notifyCharacteristicCallback,
             self.requestCallback,
             self.updateCallback];
}

- (NSError *)errorForResult:(CBATTError)result
{
    return result == CBATTErrorSuccess ? nil : [NSError errorWithDomain:CBErrorDomain code:result userInfo:@{}];
}

- (CBATTRequest *)requestForCharacteristic:(CBCharacteristic *)characteristic
{
    // Work around CBATTRequest's init NS_UNAVAILABLE
    CBATTRequest *request = [[[CBATTRequest class] alloc] init];
    [request setValue:characteristic forKey:@"characteristic"];
    [request setValue:self forKey:@"central"];
    return request;
}

- (void)setStaticValue:(NSData * _Nullable)value forCharacteristic:(CBCharacteristic *)characteristic
{
    CBUUID *outerKey = characteristic.service.UUID;
    CBUUID *innerKey = characteristic.UUID;
    NSMutableDictionary* staticValueDictionary = self.staticCharacteristicValues[outerKey];
    if (staticValueDictionary == nil && value == nil) {
        return;
    }
    if (staticValueDictionary == nil) {
        staticValueDictionary = [NSMutableDictionary dictionary];
    }
    if (value == nil) {
        [staticValueDictionary removeObjectForKey:innerKey];
    }
    else {
        staticValueDictionary[innerKey] = value;
    }
    if (staticValueDictionary.count == 0) {
        [self.staticCharacteristicValues removeObjectForKey:outerKey];
    }
    else {
        self.staticCharacteristicValues[outerKey] = staticValueDictionary;
    }
}

- (NSData * _Nullable)staticValueForCharacteristic:(CBCharacteristic *)characteristic
{
    NSData *value = nil;
    CBUUID *outerKey = characteristic.service.UUID;
    CBUUID *innerKey = characteristic.UUID;
    NSDictionary* staticValueDictionary = self.staticCharacteristicValues[outerKey];
    if (staticValueDictionary != nil) {
        value = staticValueDictionary[innerKey];
    }
    return value;
}

#pragma mark - RZBMockPeripheralDelegate

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs
{
    NSMutableArray *services = [NSMutableArray array];
    for (CBMutableService *service in self.peripheralManager.services) {
        if ([serviceUUIDs containsObject:service.UUID]) {
            [services addObject:service];
        }
    }
    [self.discoverServiceCallback dispatch:^(NSError *injectedError) {
        [peripheral fakeDiscoverService:services error:injectedError];
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBMutableService *)service
{
    NSAssert([service isKindOfClass:[CBMutableService class]], @"");

    NSMutableArray *characteristics = [NSMutableArray array];
    for (CBMutableCharacteristic *characteristic in service.characteristics) {
        NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");
        if ([characteristicUUIDs containsObject:characteristic.UUID]) {
            [characteristics addObject:characteristic];
        }
    }
    [self.discoverCharacteristicCallback dispatch:^(NSError *injectedError) {
        [peripheral fakeDiscoverCharacteristics:characteristics forService:service error:injectedError];
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(CBMutableCharacteristic *)characteristic
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    typeof(self) weakSelf = self;
    [self.readCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            NSData* staticValue = [self staticValueForCharacteristic:characteristic];
            if (staticValue == nil) {
                CBATTRequest *readRequest = [weakSelf requestForCharacteristic:characteristic];
                [weakSelf.readRequests addObject:readRequest];
                [weakSelf.peripheralManager fakeReadRequest:readRequest];
            }
            else {
                [peripheral fakeCharacteristic:characteristic updateValue:staticValue error:nil];
            }
        }
        else {
            [peripheral fakeCharacteristic:characteristic updateValue:characteristic.value error:injectedError];
        }
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(CBMutableCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    typeof(self) weakSelf = self;
    [self.writeCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (type == CBCharacteristicWriteWithResponse && injectedError) {
            [peripheral fakeCharacteristic:characteristic writeResponseWithError:injectedError];
        }
        else {
            if (injectedError) {
                RZBLogSimulation(@"writeCharacteristicCallback can not inject an error for a write without response.");
                RZBLogSimulation(@"If the write will cause an update, use updateCallback to inject an error in response to the write");
            }
            // FEATURE: The inbound data could be broken up into an array of write requests based on maximumUpdateValueLength.
            CBATTRequest *writeRequest = [weakSelf requestForCharacteristic:characteristic];
            writeRequest.value = data;
            if (type == CBCharacteristicWriteWithResponse) {
                [weakSelf.writeRequests addObject:writeRequest];
            }
            [weakSelf.peripheralManager fakeWriteRequest:writeRequest];
        }
    }];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBMutableCharacteristic *)characteristic
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    typeof(self) weakSelf = self;
    [self.notifyCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (enabled) {
            [weakSelf.subscribedCharacteristics addObject:characteristic];
        }
        else {
            [weakSelf.subscribedCharacteristics removeObject:characteristic];
        }

        if (injectedError == nil) {
            [weakSelf.peripheralManager fakeNotifyState:enabled
                                                central:(id)weakSelf.central
                                         characteristic:(id)characteristic];
        }
        [peripheral fakeCharacteristic:characteristic notify:enabled error:injectedError];
    }];
}

- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)peripheral
{
    typeof(self) weakSelf = self;
    [self.readRSSICallback dispatch:^(NSError *injectedError) {
        [peripheral fakeRSSI:weakSelf.RSSI error:injectedError];
    }];
}

#pragma mark - RZBMockPeripheralManagerDelegate

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager startAdvertising:(NSDictionary *)advertisementData
{
    RZBLogSimulation(@"PeripheralManager is discoverable");
    self.scanCallback.paused = NO;
}

- (void)mockPeripheralManagerStopAdvertising:(RZBMockPeripheralManager *)peripheralManager
{
    RZBLogSimulation(@"PeripheralManager is not discoverable");
    self.scanCallback.paused = YES;
}

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result
{
    typeof(self) weakSelf = self;
    NSAssert([request.characteristic isKindOfClass:[CBMutableCharacteristic class]], @"Invalid characteristic");
    [self.requestCallback dispatch:^(NSError * _Nullable injectedError) {
        NSError *error = injectedError ?: [weakSelf errorForResult:result];

        if ([weakSelf.readRequests containsObject:request]) {
            [weakSelf.readRequests removeObject:request];
            if (weakSelf.peripheral.state == CBPeripheralStateConnected) {
                [weakSelf.peripheral fakeCharacteristic:(CBMutableCharacteristic *)request.characteristic updateValue:request.value error:error];
            }
            else {
                RZBLogSimulation(@"Ignoring RZBMockPeripheralManager read response since the peripheral is not connected");
            }
        }
        else if ([weakSelf.writeRequests containsObject:request]) {
            [weakSelf.writeRequests removeObject:request];
            if (weakSelf.peripheral.state == CBPeripheralStateConnected) {
                [weakSelf.peripheral fakeCharacteristic:(CBMutableCharacteristic *)request.characteristic writeResponseWithError:error];
            }
            else {
                RZBLogSimulation(@"Ignoring RZBMockPeripheralManager write response since the peripheral is not connected");
            }
        }
        else {
            RZBLogSimulation(@"Not responding to write without response");
        }
    }];
}

- (BOOL)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals
{
    typeof(self) weakSelf = self;
    [self.updateCallback dispatch:^(NSError * _Nullable injectedError) {
        if (weakSelf.peripheral.state == CBPeripheralStateConnected) {
            [weakSelf.peripheral fakeCharacteristic:characteristic updateValue:value error:injectedError];
        }
        else {
            RZBLogSimulation(@"Ignoring RZBMockPeripheralManager updateValue since the peripheral is not connected");
        }
    }];
    // We don't have any buffer mechanism, so always return YES
    return YES;
}

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central
{}

// These [c|sh]ould drive peripheral:didModifyServices:
- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager addService:(CBMutableService *)service
{
    // Check for static characteristic values provided when the service is added.
    for (CBMutableCharacteristic *characteristic in service.characteristics) {
        NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");
        if (characteristic.value != nil) {
            [self setStaticValue:characteristic.value forCharacteristic:characteristic];
        }
    }
}

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager removeService:(CBMutableService *)service
{
    // Clear static characteristic values associated with the removed service.
    [self.staticCharacteristicValues removeObjectForKey:service.UUID];
}

- (void)mockPeripheralManagerRemoveAllServices:(RZBMockPeripheralManager *)peripheralManager
{
    // Clear all static characteristic values.
    [self.staticCharacteristicValues removeAllObjects];
}

@end
