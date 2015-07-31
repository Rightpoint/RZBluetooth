//
//  RZBTestService.m
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockService.h"
#import "RZBMockPeripheral.h"
#import "RZBMockCentralManager.h"
#import "RZBMockCharacteristic.h"

@implementation RZBMockService

- (RZBMockCharacteristic *)newCharacteristicForUUID:(CBUUID *)characteristicUUID
{
    RZBMockCharacteristic *characteristic = [[RZBMockCharacteristic alloc] init];
    characteristic.UUID = characteristicUUID;
    characteristic.service = (id)self;
    return characteristic;
}

- (CBCharacteristic *)characteristicForUUID:(CBUUID *)characteristicUUID
{
    for (CBCharacteristic *characteristic in self.characteristics) {
        if ([characteristic.UUID isEqual:characteristicUUID]) {
            return characteristic;
        }
    }
    return nil;
}

- (void)fakeDiscoverCharacteristicsWithUUIDs:(NSArray *)characteristicUUIDs error:(NSError *)error
{
    NSMutableArray *characteristics = [NSMutableArray array];
    for (CBUUID *characteristicUUID in characteristicUUIDs) {
        [characteristics addObject:[self newCharacteristicForUUID:characteristicUUID]];
    }
    [self fakeDiscoverCharacteristics:characteristics error:error];
}

- (void)fakeDiscoverCharacteristics:(NSArray *)services error:(NSError *)error
{
    NSMutableSet *existing = self.characteristics ? [NSMutableSet setWithArray:self.characteristics] : [NSMutableSet set];
    if (services) {
        [existing addObjectsFromArray:services];
    }
    self.characteristics = [existing allObjects];
    RZBMockPeripheral *peripheral = self.peripheral;
    dispatch_async(peripheral.mockCentralManager.queue, ^{
        [peripheral.delegate peripheral:(id)peripheral didDiscoverCharacteristicsForService:(id)self error:error];
    });
}

@end
