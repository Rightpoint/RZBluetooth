//
//  CBPeripheral+RZBBattery.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+RZBBattery.h"
#import "CBUUID+RZBPublic.h"

@implementation RZBPeripheral (RZBBattery)

- (void)fetchBatteryLevel:(RZBBatteryReadCompletion)completion
{
    [self readCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                     serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                      completion:^(CBCharacteristic *characteristic, NSError *error) {
                          uint8_t level;
                          [characteristic.value getBytes:&level length:sizeof(level)];
                          completion(level, error);
                      }];
}

- (void)addBatteryLevelObserver:(RZBBatteryReadCompletion)update completion:(RZBBatteryCompletion)completion
{
    [self addObserverForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                               serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                                  onChange:^(CBCharacteristic *characteristic, NSError *error) {
                                      uint8_t level;
                                      [characteristic.value getBytes:&level length:sizeof(level)];
                                      update(level, error);
                                  } completion:^(CBCharacteristic *characteristic, NSError *error) {
                                      completion(error);
                                  }];
}

- (void)removeBatteryLevelObserver:(RZBBatteryCompletion)completion
{
    [self removeObserverForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                  serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                                   completion:^(CBCharacteristic *characteristic, NSError *error) {
                                       completion(error);
                                   }];
}

@end
