//
//  RZBSimulatedDevice.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedDevice.h"
#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedCentral+Private.h"

@interface RZBSimulatedDevice ()

@property (strong, nonatomic, readonly) NSMutableDictionary *readHandlers;
@property (strong, nonatomic, readonly) NSMutableDictionary *writeHandlers;

@end

@implementation RZBSimulatedDevice

- (instancetype)initWithQueue:(dispatch_queue_t)queue options:(NSDictionary *)options peripheralManagerClass:(Class)peripheralManagerClass
{
    self = [super init];
    if (self) {
        _identifier = [NSUUID UUID];
        _readHandlers = [NSMutableDictionary dictionary];
        _writeHandlers = [NSMutableDictionary dictionary];
        _peripheralManager = [[peripheralManagerClass alloc] initWithDelegate:self queue:queue];
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
        CBAttributePermissions permissions = CBAttributePermissionsReadable | CBAttributePermissionsWriteable;
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
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error adding service %@", service);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{

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
