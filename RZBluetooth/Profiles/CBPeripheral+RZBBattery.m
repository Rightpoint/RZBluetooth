//
//  CBPeripheral+RZBBattery.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+RZBBattery.h"
#import "CBPeripheral+RZBHelper.h"

@implementation CBUUID (RZBBattery)

+ (CBUUID *)rzb_UUIDForBatteryService
{
    return [CBUUID UUIDWithString:@"180F"];
}

+ (CBUUID *)rzb_UUIDForBatteryLevelCharacteristic
{
    return [CBUUID UUIDWithString:@"2A19"];
}


@end

@implementation CBPeripheral (RZBBattery)

- (void)rzb_fetchBatteryLevel:(RZBBatteryCompletion)completion
{
    [self rzb_readCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                         serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                          completion:^(CBCharacteristic *characteristic, NSError *error) {
                              uint8_t level;
                              [characteristic.value getBytes:&level length:sizeof(level)];
                              completion(level, error);
                         }];
}

@end
