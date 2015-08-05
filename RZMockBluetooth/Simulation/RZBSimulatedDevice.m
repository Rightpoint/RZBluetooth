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

@implementation RZBSimulatedDevice

- (instancetype)initWithSimulatedCentral:(RZBSimulatedCentral *)simulatedCentral
{
    self = [super init];
    if (self) {
        dispatch_queue_t queue = simulatedCentral.mockCentralManager.queue;
        _identifier = [NSUUID UUID];
        _simulatedCentral = simulatedCentral;
        _peripheralManager = [[RZBMockPeripheralManager alloc] initWithDelegate:self queue:queue];
        [_simulatedCentral addSimulatedDeviceWithIdentifier:_identifier peripheralManager:_peripheralManager];
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

- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary
{
    CBMutableService *service = [self serviceForRepresentable:bluetoothRepresentable isPrimary:isPrimary];
    [self.peripheralManager addService:service];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
}

@end
