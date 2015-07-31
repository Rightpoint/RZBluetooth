//
//  RZBTestCharacteristic.m
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCharacteristic.h"
#import "RZBMockPeripheral.h"
#import "RZBMockCentralManager.h"
#import "RZBMockService.h"

@implementation RZBMockCharacteristic

- (instancetype)initWithType:(CBUUID *)UUID properties:(CBCharacteristicProperties)properties value:(NSData *)value permissions:(CBAttributePermissions)permissions
{
    self = [super init];
    if (self) {
        _UUID = UUID;
        _properties = properties;
        _value = value;
        _permissions = permissions;
    }
    return self;
}

- (void)fakeUpdateValue:(NSData *)value error:(NSError *)error
{
    RZBMockPeripheral *peripheral = self.service.peripheral;
    dispatch_async(peripheral.mockCentralManager.queue, ^{
        self.value = value;
        [peripheral.delegate peripheral:(id)peripheral didUpdateValueForCharacteristic:(id)self error:error];
    });
}

- (void)fakeWriteResponseWithError:(NSError *)error
{
    RZBMockPeripheral *peripheral = self.service.peripheral;
    dispatch_async(peripheral.mockCentralManager.queue, ^{
        [peripheral.delegate peripheral:(id)peripheral didWriteValueForCharacteristic:(id)self error:error];
    });
}

- (void)fakeNotify:(BOOL)notifyState error:(NSError *)error
{
    RZBMockPeripheral *peripheral = self.service.peripheral;
    self.isNotifying = notifyState;
    dispatch_async(peripheral.mockCentralManager.queue, ^{
        [peripheral.delegate peripheral:(id)peripheral didUpdateNotificationStateForCharacteristic:(id)self error:error];
    });
}

@end
