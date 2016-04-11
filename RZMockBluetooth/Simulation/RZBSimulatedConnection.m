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

@implementation RZBSimulatedConnection

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                 peripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager
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
        _readRequests = [NSMutableArray array];
        _writeRequests = [NSMutableArray array];
        _subscribedCharacteristics = [NSMutableArray array];

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
        if (self.peripheral.state == CBPeripheralStateConnected ||
            self.peripheral.state == CBPeripheralStateConnecting) {
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
    self.peripheral.state = CBPeripheralStateDisconnecting;
    [self.cancelConncetionCallback dispatch:^(NSError *injectedError) {
        [self.central.mockCentralManager fakeDisconnectPeripheralWithUUID:self.identifier
                                                                    error:injectedError];
    }];
}

- (NSArray *)connectionDependentCallbacks
{
    return @[self.connectCallback,
             self.discoverServiceCallback,
             self.discoverCharacteristicCallback,
             self.readRSSICallback,
             self.readCharacteristicCallback,
             self.writeCharacteristicCallback,
             self.notifyCharacteristicCallback];
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

#pragma mark - RZBMockPeripheralDelegate

- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral discoverServices:(NSArray *)serviceUUIDs
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

- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBMutableService *)service
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

- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral readValueForCharacteristic:(CBMutableCharacteristic *)characteristic
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    [self.readCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            if (characteristic.value == nil) {
                CBATTRequest *readRequest = [self requestForCharacteristic:characteristic];
                [self.readRequests addObject:readRequest];
                [self.peripheralManager fakeReadRequest:readRequest];
            }
            else {
                [peripheral fakeCharacteristic:characteristic updateValue:characteristic.value error:nil];
            }
        }
        else {
            [peripheral fakeCharacteristic:characteristic updateValue:characteristic.value error:injectedError];
        }
    }];
}

- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral writeValue:(NSData *)data forCharacteristic:(CBMutableCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    [self.writeCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (injectedError == nil) {
            // FEATURE: The inbound data could be broken up into an array of write requests based on maximumUpdateValueLength.
            CBATTRequest *writeRequest = [self requestForCharacteristic:characteristic];
            writeRequest.value = data;
            if (type == CBCharacteristicWriteWithResponse) {
                [self.writeRequests addObject:writeRequest];
            }
            [self.peripheralManager fakeWriteRequest:writeRequest];
        }
        else if (type == CBCharacteristicWriteWithResponse) {
            [peripheral fakeCharacteristic:characteristic writeResponseWithError:injectedError];
        }
    }];
}

- (void)mockPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(CBMutableCharacteristic *)characteristic
{
    NSAssert([characteristic isKindOfClass:[CBMutableCharacteristic class]], @"");

    [self.notifyCharacteristicCallback dispatch:^(NSError *injectedError) {
        if (enabled) {
            [self.subscribedCharacteristics addObject:characteristic];
        }
        else {
            [self.subscribedCharacteristics removeObject:characteristic];
        }

        if (injectedError == nil) {
            [self.peripheralManager fakeNotifyState:enabled central:(id)self.central characteristic:(id)characteristic];
        }
        [peripheral fakeCharacteristic:characteristic notify:enabled error:injectedError];
    }];
}

- (void)mockPeripheralReadRSSI:(CBPeripheral<RZBMockedPeripheral> *)peripheral
{
    [self.readRSSICallback dispatch:^(NSError *injectedError) {
        [peripheral fakeRSSI:self.RSSI error:injectedError];
    }];
}

#pragma mark - RZBMockPeripheralManagerDelegate

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager startAdvertising:(NSDictionary *)advertisementData
{
    self.scanCallback.paused = NO;
}

- (void)mockPeripheralManagerStopAdvertising:(RZBMockPeripheralManager *)peripheralManager
{
    self.scanCallback.paused = YES;
}

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result
{
    NSAssert([request.characteristic isKindOfClass:[CBMutableCharacteristic class]], @"Invalid characteristic");
    [self.requestCallback dispatch:^(NSError * _Nullable injectedError) {
        NSError *error = injectedError ?: [self errorForResult:result];

        if ([self.readRequests containsObject:request]) {
            [self.readRequests removeObject:request];
            if (self.peripheral.state == CBPeripheralStateConnected) {
                [self.peripheral fakeCharacteristic:(CBMutableCharacteristic *)request.characteristic updateValue:request.value error:error];
            }
        }
        else if ([self.writeRequests containsObject:request]) {
            [self.writeRequests removeObject:request];
            if (self.peripheral.state == CBPeripheralStateConnected) {
                [self.peripheral fakeCharacteristic:(CBMutableCharacteristic *)request.characteristic writeResponseWithError:error];
            }
        }
    }];
}

- (BOOL)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals
{
    if (self.peripheral.state == CBPeripheralStateConnected) {
        [self.peripheral fakeCharacteristic:characteristic updateValue:value error:nil];
    }
    // We don't have any buffer mechanism, so always return YES
    return YES;
}

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central
{}

// These [c|sh]ould drive peripheral:didModifyServices:
- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager addService:(CBMutableService *)service
{}

- (void)mockPeripheralManager:(RZBMockPeripheralManager *)peripheralManager removeService:(CBMutableService *)service
{}

- (void)mockPeripheralManagerRemoveAllServices:(RZBMockPeripheralManager *)peripheralManager
{}

@end
