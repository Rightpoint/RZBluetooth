//
//  RZBMockPeripheral.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralManager.h"
#import "RZBMockPeripheral.h"

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

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service
{
    [self.mockDelegate mockPeripheral:self discoverCharacteristics:characteristicUUIDs forService:service];
}

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic
{
    [self.mockDelegate mockPeripheral:self readValueForCharacteristic:characteristic];
}

- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [self.mockDelegate mockPeripheral:self writeValue:data forCharacteristic:characteristic type:type];
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic
{
    [self.mockDelegate mockPeripheral:self setNotifyValue:enabled forCharacteristic:characteristic];
}

- (CBMutableService *)newServiceForUUID:(CBUUID *)serviceUUID
{
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    return service;
}

- (CBMutableCharacteristic *)newCharacteristicForUUID:(CBUUID *)serviceUUID
{
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:serviceUUID
                                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify
                                                                                      value:nil
                                                                                permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    return characteristic;
}

- (CBMutableService *)serviceForUUID:(CBUUID *)serviceUUID
{
    for (CBMutableService *service in self.services) {
        if ([service.UUID isEqual:serviceUUID]) {
            return service;
        }
    }
    return nil;
}

- (void)performFakeAction:(void(^)(void))block
{
    @synchronized (self) {
        self.fakeActionCount += 1;
    }
    dispatch_async(self.mockCentralManager.queue, ^{
        block();
        @synchronized (self) {
            self.fakeActionCount -= 1;
        }
    });
}

- (void)fakeRSSI:(NSNumber *)RSSI error:(NSError *)error
{
#if TARGET_OS_OSX
    self.RSSI = RSSI;
#endif
    [self performFakeAction:^{
#if TARGET_OS_OSX
        [self.delegate peripheralDidUpdateRSSI:(id)self error: error];
#else
        [self.delegate peripheral:(id)self didReadRSSI:RSSI error:error];
#endif
    }];
}

- (void)fakeDiscoverService:(NSArray<CBMutableService *> *)services error:(NSError *)error
{
    NSMutableSet *existing = self.services ? [NSMutableSet setWithArray:self.services] : [NSMutableSet set];
    if (services) {
        [existing addObjectsFromArray:services];
    }
    self.services = [existing allObjects];
    for (CBMutableService *service in self.services) {
        [service setValue:self forKey:@"peripheral"];
    }
    [self performFakeAction:^{
        [self.delegate peripheral:(id)self didDiscoverServices:error];
    }];
}

- (void)fakeDiscoverServicesWithUUIDs:(NSArray<CBUUID *> *)serviceUUIDs error:(NSError *)error
{
    NSMutableArray *services = [NSMutableArray array];
    for (CBUUID *serviceUUID in serviceUUIDs) {
        [services addObject:[self newServiceForUUID:serviceUUID]];
    }
    [self fakeDiscoverService:services error:error];
}

- (void)fakeUpdateName:(NSString *)name;
{
    [self performFakeAction:^{
        self.name = name;
        [self.delegate peripheralDidUpdateName:(id)self];
    }];
}

- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs forService:(CBMutableService *)service error:(NSError *)error
{
    NSMutableArray *characteristics = [NSMutableArray array];
    for (CBUUID *characteristicUUID in characteristicUUIDs) {
        [characteristics addObject:[self newCharacteristicForUUID:characteristicUUID]];
    }
    [self fakeDiscoverCharacteristics:characteristics forService:service error:error];
}

- (void)fakeDiscoverCharacteristics:(NSArray<CBCharacteristic *> *)characteristics forService:(CBMutableService *)service error:(NSError *)error
{
    NSMutableSet *existing = service.characteristics ? [NSMutableSet setWithArray:service.characteristics] : [NSMutableSet set];
    if (characteristics) {
        [existing addObjectsFromArray:characteristics];
    }
    service.characteristics = [existing allObjects];
    [self performFakeAction:^{
        [self.delegate peripheral:(id)self didDiscoverCharacteristicsForService:(id)service error:error];
    }];
}

- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic updateValue:(NSData *)value error:(NSError *)error
{
    [self performFakeAction:^{
        characteristic.value = value;
        [self.delegate peripheral:(id)self didUpdateValueForCharacteristic:(id)characteristic error:error];
    }];
}

- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic writeResponseWithError:(NSError *)error;
{
    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self performFakeAction:^{
            [self.delegate peripheral:(id)self didWriteValueForCharacteristic:(id)characteristic error:error];
        }];
    }
}

- (void)fakeCharacteristic:(CBMutableCharacteristic *)characteristic notify:(BOOL)notifyState error:(NSError *)error
{
    [self performFakeAction:^{
        if (error == nil) {
            [characteristic setValue:@(notifyState) forKey:@"isNotifying"];
        }
        [self.delegate peripheral:(id)self didUpdateNotificationStateForCharacteristic:(id)characteristic error:error];
    }];
}

@end
