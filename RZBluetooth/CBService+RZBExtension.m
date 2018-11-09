//
//  CBService+RZBExtension.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBService+RZBExtension.h"

@implementation CBPeripheral (RZBExtension)

- (CBService * __nullable)rzb_serviceForUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(serviceUUID);
    for (CBService *service in self.services) {
        if ([service.UUID isEqual:serviceUUID]) {
            return service;
        }
    }
    return nil;
}

@end

@implementation CBService (RZBExtension)

- (CBCharacteristic *)rzb_characteristicForUUID:(CBUUID *)characteristicUUID
{
    for (CBCharacteristic *characteristic in self.characteristics) {
        if ([characteristic.UUID isEqual:characteristicUUID]) {
            return characteristic;
        }
    }
    return nil;
}

@end
