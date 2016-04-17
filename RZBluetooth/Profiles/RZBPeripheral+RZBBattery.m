//
//  RZBPeripheral+RZBBattery.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBPeripheral+RZBBattery.h"
#import "CBUUID+RZBPublic.h"

@implementation RZBPeripheral (RZBBattery)

- (void)fetchBatteryLevel:(RZBBatteryReadCompletion)completion
{
    NSParameterAssert(completion);
    [self readCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                     serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                      completion:^(CBCharacteristic *characteristic, NSError *error) {
                          uint8_t level;
                          [characteristic.value getBytes:&level length:sizeof(level)];
                          completion(level, error);
                      }];
}

- (void)addBatteryLevelObserver:(RZBBatteryReadCompletion)update completion:(RZBErrorBlock)completion
{
    NSParameterAssert(update);
    completion = completion ?: ^(NSError *e) {};
    [self enableNotifyForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                                   onUpdate:^(CBCharacteristic *characteristic, NSError *error) {
                                       uint8_t level;
                                       [characteristic.value getBytes:&level length:sizeof(level)];
                                       update(level, error);
                                   } completion:^(CBCharacteristic *characteristic, NSError *error) {
                                       completion(error);
                                   }];
}

- (void)removeBatteryLevelObserver:(RZBErrorBlock)completion
{
    completion = completion ?: ^(NSError *e) {};
    [self clearNotifyBlockForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                    serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                                     completion:^(CBCharacteristic *characteristic, NSError *error) {
                                         completion(error);
                                     }];
}

@end
