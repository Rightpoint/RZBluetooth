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

@end
