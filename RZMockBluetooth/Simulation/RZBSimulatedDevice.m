//
//  RZBSimulatedDevice.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedDevice.h"
#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedCentral.h"

@interface RZBSimulatedDevice ()

@property (strong, nonatomic, readonly) NSMutableDictionary *readHandlers;
@property (strong, nonatomic, readonly) NSMutableDictionary *writeHandlers;
@property (strong, nonatomic, readonly) NSMutableDictionary *subscribeHandlers;

@end

@implementation RZBSimulatedDevice

- (instancetype)initMockWithIdentifier:(NSUUID *)identifier
                                 queue:(dispatch_queue_t)queue
                               options:(NSDictionary *)options;
{
    self = [super init];
    if (self) {
        _queue = queue ?: dispatch_get_main_queue();
        _identifier = identifier;
        _readHandlers = [NSMutableDictionary dictionary];
        _writeHandlers = [NSMutableDictionary dictionary];
        _subscribeHandlers = [NSMutableDictionary dictionary];
        _peripheralManager = (id)[[RZBMockPeripheralManager alloc] initWithDelegate:self
                                                                              queue:queue
                                                                            options:options];
        _values = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue
                      options:(NSDictionary *)options;
{
    self = [super init];
    if (self) {
        _queue = queue ?: dispatch_get_main_queue();
        _readHandlers = [NSMutableDictionary dictionary];
        _writeHandlers = [NSMutableDictionary dictionary];
        _subscribeHandlers = [NSMutableDictionary dictionary];
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:queue
                                                                   options:options];
        _values = [NSMutableDictionary dictionary];
    }
    return self;
}

- (RZBMockPeripheralManager *)mockPeripheralManager
{
    RZBMockPeripheralManager *mockPeripheralManager = (id)self.peripheralManager;
    NSAssert([mockPeripheralManager isKindOfClass:[RZBMockPeripheralManager class]], @"%@ is not configured with a mock peripheral manager", self);
    return mockPeripheralManager;
}

- (CBMutableService *)serviceForRepresentable:(id<RZBBluetoothRepresentable>)representable isPrimary:(BOOL)isPrimary
{
    CBMutableService *service = [[CBMutableService alloc] initWithType:[representable.class serviceUUID] primary:isPrimary];

    NSDictionary *characteristicsByUUID = [representable.class characteristicUUIDsByKey];
    NSMutableArray *characteristics = [NSMutableArray array];
    [characteristicsByUUID enumerateKeysAndObjectsUsingBlock:^(NSString *key, CBUUID *UUID, BOOL *stop) {
        CBCharacteristicProperties properties = [representable.class characteristicPropertiesForKey:key];
        CBAttributePermissions permissions = CBAttributePermissionsReadable;
        id value = [representable valueForKey:key];

        if (value) {
            NSData *data = [representable.class dataForKey:key fromValue:value];
            CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:UUID
                                                                                         properties:properties
                                                                                              value:data
                                                                                        permissions:permissions];
            [characteristics addObject:characteristic];
        }
    }];
    service.characteristics = characteristics;
    return service;
}

- (void)startAdvertising
{
    NSAssert(self.peripheralManager.isAdvertising == NO, @"Already Advertising");
    NSAssert([self advertisedServices] != nil, @"Must Specify the services that should be advertised by setting the advertisedServices property prior to advertising");
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:[self advertisedServices]}];
}

- (void)stopAdvertising
{
    [self.peripheralManager stopAdvertising];
}

- (void)addService:(CBMutableService *)service
{
    [[self mutableArrayValueForKey:@"services"] addObject:service];
    [self.peripheralManager addService:service];
}

- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary
{
    NSParameterAssert(bluetoothRepresentable);
    CBMutableService *service = [self serviceForRepresentable:bluetoothRepresentable isPrimary:isPrimary];
    [self addService:service];
}

- (void)addReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBSimulatedDeviceRead)handler;
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(handler);
    self.readHandlers[characteristicUUID] = [handler copy];
}

- (void)addWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBSimulatedDeviceRead)handler;
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(handler);
    self.writeHandlers[characteristicUUID] = [handler copy];
}

- (void)addSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBSimulatedDeviceSubscribe)handler
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(handler);
    self.subscribeHandlers[characteristicUUID] = [handler copy];
}

- (CBMutableCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID
{
    for (CBMutableService *service in self.services) {
        for (CBMutableCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:characteristicUUID]) {
                return characteristic;
            }
        }
    }
    return nil;
}


#pragma mark - CBPeripheralDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (self.onStateChange) {
        self.onStateChange(peripheral.state);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Add Service: %@ (%@)", service, error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    RZBSimulatedDeviceSubscribe handler = self.subscribeHandlers[characteristic.UUID];
    if (handler) {
        handler(YES);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    RZBSimulatedDeviceSubscribe handler = self.subscribeHandlers[characteristic.UUID];
    if (handler) {
        handler(NO);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    RZBSimulatedDeviceRead read = self.readHandlers[request.characteristic.UUID];
    CBATTError result = CBATTErrorRequestNotSupported;
    if (read) {
        result = read(request);
    }
    else {
        NSLog(@"Un-handled read for %@", request);
    }
    [peripheral respondToRequest:request withResult:result];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    CBATTError result = CBATTErrorSuccess;
    for (CBATTRequest *request in requests) {
        RZBSimulatedDeviceRead write = self.writeHandlers[request.characteristic.UUID];
        if (write) {
            result = MAX(result, write(request));
        }
        else {
            NSLog(@"Un-handled write for %@", request);
            result = MAX(result, CBATTErrorRequestNotSupported);
        }
    }
    [peripheral respondToRequest:requests.firstObject withResult:result];
}

@end
