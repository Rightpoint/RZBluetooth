//
//  RZBTestPeripheral.m
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralManager.h"
#import "RZBMockPeripheral.h"
#import "RZBMockService.h"
#import "RZBMockCharacteristic.h"
#import "CBPeripheral+RZBExtension.h"

@import ObjectiveC.runtime;

@implementation RZBMockPeripheral

+ (BOOL)resolveInstanceMethod:(SEL)aSelector
{
    BOOL resolved = [super resolveInstanceMethod:aSelector];
    if (resolved == NO) {
        Method method = class_getInstanceMethod([CBPeripheral class], aSelector);
        if (method) {
            const char *types = method_getTypeEncoding(method);
            IMP impl = method_getImplementation(method);
            class_addMethod(self, aSelector, impl, types);
            resolved = YES;
        }
    }
    return resolved;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [RZBMockPeripheral isKindOfClass:aClass] || [CBPeripheral isSubclassOfClass:aClass];
}

- (void)readRSSI
{
    [self.mockDelegate mockPeripheralReadRSSI:self];
}

- (void)discoverServices:(NSArray *)serviceUUIDs
{
    [self.mockDelegate mockPeripheral:self discoverServices:serviceUUIDs];
}

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(RZBMockService *)service
{
    [self.mockDelegate mockPeripheral:self discoverCharacteristics:characteristicUUIDs forService:service];
}

- (void)readValueForCharacteristic:(RZBMockCharacteristic *)characteristic
{
    [self.mockDelegate mockPeripheral:self readValueForCharacteristic:characteristic];
}

- (void)writeValue:(NSData *)data forCharacteristic:(RZBMockCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [self.mockDelegate mockPeripheral:self writeValue:data forCharacteristic:characteristic type:type];
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(RZBMockCharacteristic *)characteristic
{
    [self.mockDelegate mockPeripheral:self setNotifyValue:enabled forCharacteristic:characteristic];
}

- (RZBMockService *)newServiceForUUID:(CBUUID *)serviceUUID
{
    RZBMockService *service = [[RZBMockService alloc] init];
    service.UUID = serviceUUID;
    service.peripheral = (id)self;
    return service;
}

- (RZBMockService *)serviceForUUID:(CBUUID *)serviceUUID
{
    for (RZBMockService *service in self.services) {
        if ([service.UUID isEqual:serviceUUID]) {
            return service;
        }
    }
    return nil;
}

- (void)fakeRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    dispatch_async(self.mockCentralManager.queue, ^{
        [self.delegate peripheral:(id)self didReadRSSI:RSSI error:error];
    });
}

- (void)fakeDiscoverService:(NSArray *)services error:(NSError *)error
{
    NSMutableSet *existing = self.services ? [NSMutableSet setWithArray:self.services] : [NSMutableSet set];
    if (services) {
        [existing addObjectsFromArray:services];
    }
    self.services = [existing allObjects];
    dispatch_async(self.mockCentralManager.queue, ^{
        [self.delegate peripheral:(id)self didDiscoverServices:error];
    });
}

- (void)fakeDiscoverServicesWithUUIDs:(NSArray *)serviceUUIDs error:(NSError *)error
{
    NSMutableArray *services = [NSMutableArray array];
    for (CBUUID *serviceUUID in serviceUUIDs) {
        [services addObject:[self newServiceForUUID:serviceUUID]];
    }
    [self fakeDiscoverService:services error:error];
}

- (void)fakeUpdateName:(NSString *)name;
{
    dispatch_async(self.mockCentralManager.queue, ^{
        self.name = name;
        [self.delegate peripheralDidUpdateName:(id)self];
    });
}

- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray *)characteristicUUIDs forService:(RZBMockService *)service error:(NSError *)error
{
    NSMutableArray *characteristics = [NSMutableArray array];
    for (CBUUID *characteristicUUID in characteristicUUIDs) {
        [characteristics addObject:[service newCharacteristicForUUID:characteristicUUID]];
    }
    [self fakeDiscoverCharacteristics:characteristics forService:service error:error];
}

- (void)fakeDiscoverCharacteristics:(NSArray *)services forService:(RZBMockService *)service error:(NSError *)error
{
    NSMutableSet *existing = service.characteristics ? [NSMutableSet setWithArray:service.characteristics] : [NSMutableSet set];
    if (services) {
        [existing addObjectsFromArray:services];
    }
    service.characteristics = [existing allObjects];
    dispatch_async(self.mockCentralManager.queue, ^{
        [self.delegate peripheral:(id)self didDiscoverCharacteristicsForService:(id)service error:error];
    });
}

- (void)fakeCharacteristic:(RZBMockCharacteristic *)characteristic updateValue:(NSData *)value error:(NSError *)error
{
    dispatch_async(self.mockCentralManager.queue, ^{
        characteristic.value = value;
        [self.delegate peripheral:(id)self didUpdateValueForCharacteristic:(id)characteristic error:error];
    });
}

- (void)fakeCharacteristic:(RZBMockCharacteristic *)characteristic writeResponseWithError:(NSError *)error;
{
    dispatch_async(self.mockCentralManager.queue, ^{
        [self.delegate peripheral:(id)self didWriteValueForCharacteristic:(id)characteristic error:error];
    });
}

- (void)fakeCharacteristic:(RZBMockCharacteristic *)characteristic notify:(BOOL)notifyState error:(NSError *)error
{
    dispatch_async(self.mockCentralManager.queue, ^{
        characteristic.isNotifying = notifyState;
        [self.delegate peripheral:(id)self didUpdateNotificationStateForCharacteristic:(id)characteristic error:error];
    });
}

@end
