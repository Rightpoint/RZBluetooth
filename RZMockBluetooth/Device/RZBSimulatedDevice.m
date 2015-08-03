//
//  RZBSimulatedDevice.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedDevice.h"
#import "RZBMockService.h"
#import "RZBMockCharacteristic.h"

@implementation RZBSimulatedDevice

- (NSArray *)services
{
    if (_services == nil) {
        [self loadServices];
        NSAssert(_services != nil, @"Must set the services array in loadServices");
    }
    return _services;
}

- (void)loadServices
{
    
}

#pragma mark - RZBMockPeripheralDelegate

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverServices:(NSArray *)serviceUUIDs
{
    NSMutableArray *services = [NSMutableArray array];
    for (RZBMockService *service in self.services) {
        if ([serviceUUIDs containsObject:service.UUID]) {
            [services addObject:service];
        }
    }
    [peripheral fakeDiscoverService:services error:nil];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(RZBMockService *)service
{
    NSMutableArray *characteristics = [NSMutableArray array];
    for (RZBMockCharacteristic *characteristic in service.characteristics) {
        if ([characteristicUUIDs containsObject:characteristic.UUID]) {
            [characteristics addObject:characteristic];
        }
    }
    [service fakeDiscoverCharacteristics:characteristics error:nil];
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral readValueForCharacteristic:(RZBMockCharacteristic *)characteristic
{
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral writeValue:(NSData *)data forCharacteristic:(RZBMockCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
}

- (void)mockPeripheral:(RZBMockPeripheral *)peripheral setNotifyValue:(BOOL)enabled forCharacteristic:(RZBMockCharacteristic *)characteristic
{
}

- (void)mockPeripheralReadRSSI:(RZBMockPeripheral *)peripheral
{

}


@end
