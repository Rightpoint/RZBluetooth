//
//  RZBSimulatedDevice.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedDevice.h"
#import "RZBSimulatedCentral.h"
#import "RZBLog+Private.h"
#import "RZBEnableMock.h"

@interface RZBSimulatedDevice ()

@property (strong, nonatomic, readonly) NSMutableDictionary *readHandlers;
@property (strong, nonatomic, readonly) NSMutableDictionary *writeHandlers;
@property (strong, nonatomic, readonly) NSMutableDictionary *subscribeHandlers;
@property (strong, nonatomic, readonly) NSOperationQueue *operationQueue;

- (NSString *)keyForCharacteristicUUID:(CBUUID *)cuuid serviceUUID:(CBUUID *)suuid;
- (NSString *)keyForCharacteristic:(CBCharacteristic *)characteristic;
- (CBUUID *)serviceUUIDForCharacteristicUUID:(CBUUID *)characteristicUUID;

@end

@implementation RZBSimulatedDevice

- (instancetype)init
{
    self = [self initWithQueue:nil options:@{}];
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
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.suspended = true;
    }
    return self;
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

- (void)performPeripheralAction:(void (^)(void))action
{
    NSParameterAssert(action);
    [self.operationQueue addOperationWithBlock:action];

    // If we're using mock objects, flush the operation. The asynchronous behavior adds a lot of complexity if not needed.
    if ([_peripheralManager mock] != nil && !_operationQueue.suspended) {
        [self.operationQueue waitUntilAllOperationsAreFinished];
    }
}

- (void)startAdvertising
{
    NSAssert(self.peripheralManager.isAdvertising == NO, @"Already Advertising");
    NSAssert([self advertisedServices].count > 0, @"The device has no primary services");
    [self performPeripheralAction:^{
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: [self advertisedServices]}];
    }];
}

- (void)stopAdvertising
{
    [self performPeripheralAction:^{
        [self.peripheralManager stopAdvertising];
    }];
}

- (NSArray *)advertisedServices
{
    @synchronized (self.services) {
        return [self.services filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isPrimary == YES"]];
    }
}

- (void)addService:(CBMutableService *)service
{
    @synchronized (self.services) {
        [[self mutableArrayValueForKey:@"services"] addObject:service];
    }
    [self performPeripheralAction:^{
        [self.peripheralManager addService:service];
    }];
}

- (void)removeService:(CBMutableService *)service
{
    @synchronized (self.services) {
        [[self mutableArrayValueForKey:@"services"] removeObject:service];
    }
    [self performPeripheralAction:^{
        [self.peripheralManager removeService:service];
    }];
}

- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary
{
    NSParameterAssert(bluetoothRepresentable);
    CBMutableService *service = [self serviceForRepresentable:bluetoothRepresentable isPrimary:isPrimary];
    [self addService:service];
}

- (NSString *)keyForCharacteristicUUID:(CBUUID *)cuuid serviceUUID:(CBUUID *)suuid
{
    NSParameterAssert(cuuid);
    NSParameterAssert(suuid);
    return [NSString stringWithFormat:@"%@:%@", suuid.UUIDString, cuuid.UUIDString];
}

- (NSString *)keyForCharacteristic:(CBCharacteristic *)characteristic
{
    return [self keyForCharacteristicUUID:characteristic.UUID serviceUUID:characteristic.service.UUID];
}

- (CBUUID *)serviceUUIDForCharacteristicUUID:(CBUUID *)characteristicUUID
{
    @synchronized (self.services) {
        NSMutableArray* matches = [NSMutableArray array];
        for (CBMutableService *service in self.services) {
            for (CBMutableCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:characteristicUUID]) {
                    [matches addObject:service.UUID];
                }
            }
        }
        NSAssert(matches.count <= 1, @"Characteristic UUID found on multiple services; must specify service UUID.");
        return [matches firstObject];
    }
}

- (void)addReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID handler:(RZBATTRequestHandler)handler
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(serviceUUID);
    NSParameterAssert(handler);
    NSString *key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    @synchronized (self.readHandlers) {
        self.readHandlers[key] = [handler copy];
    }
}

- (void)addReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBATTRequestHandler)handler
{
    CBUUID *serviceUUID = [self serviceUUIDForCharacteristicUUID:characteristicUUID];
    [self addReadCallbackForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID handler:handler];
}

- (void)addWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID handler:(RZBATTRequestHandler)handler
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(serviceUUID);
    NSParameterAssert(handler);
    NSString *key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    @synchronized (self.writeHandlers) {
        self.writeHandlers[key] = [handler copy];
    }
}

- (void)addWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBATTRequestHandler)handler
{
    CBUUID *serviceUUID = [self serviceUUIDForCharacteristicUUID:characteristicUUID];
    [self addWriteCallbackForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID handler:handler];
}

- (void)addSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID handler:(RZBNotificationHandler)handler
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(serviceUUID);
    NSParameterAssert(handler);
    NSString *key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    @synchronized (self.subscribeHandlers) {
        self.subscribeHandlers[key] = [handler copy];
    }
}

- (void)addSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID handler:(RZBNotificationHandler)handler
{
    CBUUID *serviceUUID = [self serviceUUIDForCharacteristicUUID:characteristicUUID];
    [self addSubscribeCallbackForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID handler:handler];
}

- (void)removeReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(serviceUUID);
    NSString *key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    @synchronized (self.readHandlers) {
        [self.readHandlers removeObjectForKey:key];
    }
}

- (void)removeReadCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID
{
    CBUUID *serviceUUID = [self serviceUUIDForCharacteristicUUID:characteristicUUID];
    [self removeReadCallbackForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
}

- (void)removeWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(serviceUUID);
    NSString *key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    @synchronized (self.writeHandlers) {
        [self.writeHandlers removeObjectForKey:key];
    }
}

- (void)removeWriteCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID
{
    CBUUID *serviceUUID = [self serviceUUIDForCharacteristicUUID:characteristicUUID];
    [self removeReadCallbackForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
}

- (void)removeSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(characteristicUUID);
    NSParameterAssert(serviceUUID);
    NSString *key = [self keyForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
    @synchronized (self.subscribeHandlers) {
        [self.subscribeHandlers removeObjectForKey:key];
    }
}

- (void)removeSubscribeCallbackForCharacteristicUUID:(CBUUID *)characteristicUUID
{
    CBUUID *serviceUUID = [self serviceUUIDForCharacteristicUUID:characteristicUUID];
    [self removeSubscribeCallbackForCharacteristicUUID:characteristicUUID serviceUUID:serviceUUID];
}

- (CBMutableCharacteristic * _Nullable)characteristicForUUID:(CBUUID *)characteristicUUID
{
    @synchronized (self.services) {
        for (CBMutableService *service in self.services) {
            for (CBMutableCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:characteristicUUID]) {
                    return characteristic;
                }
            }
        }
        return nil;
    }
}

- (CBMutableCharacteristic * _Nullable)characteristicForUUID:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID
{
    @synchronized (self.services) {
        for (CBMutableService *service in self.services) {
            if ([service.UUID isEqual:serviceUUID]) {
                for (CBMutableCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:characteristicUUID]) {
                        return characteristic;
                    }
                }
            }
        }
        return nil;
    }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    RZBLogSimulatedDevice(@"%@ - %@", NSStringFromSelector(_cmd), peripheral);
    RZBLogSimulatedDevice(@"State=%d", (unsigned int)peripheral.state);

    RZBPeripheralManagerStateBlock stateChange = self.onStateChange;
    if (stateChange) {
        stateChange((RZBPeripheralManagerState)peripheral.state);
    }

    _operationQueue.suspended = (peripheral.state != RZBPeripheralManagerStatePoweredOn);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    RZBLogSimulatedDevice(@"%@ -  %@", NSStringFromSelector(_cmd), error);
    RZBLogSimulatedDevice(@"Service=%@", service.UUID);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    RZBLogSimulatedDevice(@"%@ -  %@", NSStringFromSelector(_cmd), characteristic.UUID);

    RZBNotificationHandler handler = nil;
    NSString *key = [self keyForCharacteristic:characteristic];
    @synchronized (self.subscribeHandlers) {
        handler = self.subscribeHandlers[key];
    }
    if (handler) {
        handler(YES);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    RZBLogSimulatedDevice(@"%@ -  %@", NSStringFromSelector(_cmd), characteristic.UUID);

    RZBNotificationHandler handler = nil;
    NSString *key = [self keyForCharacteristic:characteristic];
    @synchronized (self.subscribeHandlers) {
        handler = self.subscribeHandlers[key];
    }
    if (handler) {
        handler(NO);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    RZBLogSimulatedDevice(@"%@ -  %@", NSStringFromSelector(_cmd), request.characteristic.UUID);

    RZBATTRequestHandler read = nil;
    NSString *key = [self keyForCharacteristic:request.characteristic];
    @synchronized (self.readHandlers) {
        read = self.readHandlers[key];
    }
    CBATTError result = CBATTErrorRequestNotSupported;
    if (read) {
        result = read(request);
    }
    else {
        RZBLogSimulatedDevice(@"Unhandled read request %@", request);
    }
    [peripheral respondToRequest:request withResult:result];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    RZBLogSimulatedDevice(@"%@ -  %@", NSStringFromSelector(_cmd), RZBLogArray([requests valueForKeyPath:@"characteristic.UUID"]));

    CBATTError result = CBATTErrorSuccess;
    for (CBATTRequest *request in requests) {
        RZBATTRequestHandler write = nil;
        NSString *key = [self keyForCharacteristic:request.characteristic];
        @synchronized(self.writeHandlers) {
            write = self.writeHandlers[key];
        }
        if (write) {
            result = MAX(result, write(request));
        }
        else {
            RZBLogSimulatedDevice(@"Unhandled read request %@", request);
            result = MAX(result, CBATTErrorRequestNotSupported);
        }
    }
    [peripheral respondToRequest:requests.firstObject withResult:result];
}

@end
