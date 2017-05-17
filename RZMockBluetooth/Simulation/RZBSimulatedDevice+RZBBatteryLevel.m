//
//  RZBSimulatedDevice+RZBBatteryLevel.m
//  RZBluetooth
//
//  Created by Brian King on 8/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedDevice+RZBBatteryLevel.h"
#import "RZBPeripheral+RZBBattery.h"
#import "CBUUID+RZBPublic.h"

static NSString *const RZBBatteryLevelKey = @"batteryLevel";

@implementation RZBSimulatedDevice (RZBBatteryLevel)

- (void)addBatteryService
{
    CBMutableService *batteryService = [[CBMutableService alloc] initWithType:[CBUUID rzb_UUIDForBatteryService] primary:NO];
    CBMutableCharacteristic *batteryCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                                                                        properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyIndicate
                                                                                             value:nil
                                                                                       permissions:CBAttributePermissionsReadable];
    batteryService.characteristics = @[batteryCharacteristic];

    [self addService:batteryService];

    __block typeof(self) welf = (id)self;
    [self addReadCallbackForCharacteristicUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic]
                                   serviceUUID:[CBUUID rzb_UUIDForBatteryService]
                                       handler:^CBATTError (CBATTRequest *request) {
        NSNumber *batteryNumber = welf.values[RZBBatteryLevelKey];
        uint8_t batteryLevel = [batteryNumber unsignedIntegerValue];
        request.value = [NSData dataWithBytes:&batteryLevel length:1];
        return CBATTErrorSuccess;
    }];
}

- (void)setBatteryLevel:(uint8_t)level
{
    self.values[RZBBatteryLevelKey] = @(level);
    CBMutableCharacteristic *batteryCharacteristic = [self characteristicForUUID:[CBUUID rzb_UUIDForBatteryLevelCharacteristic] serviceUUID:[CBUUID rzb_UUIDForBatteryService]];

    NSData *value = [NSData dataWithBytes:&level length:1];
    [self.peripheralManager updateValue:value
                      forCharacteristic:batteryCharacteristic
                   onSubscribedCentrals:nil];
}

- (uint8_t)batteryLevel
{
    return [self.values[RZBBatteryLevelKey] unsignedIntegerValue];
}

@end
