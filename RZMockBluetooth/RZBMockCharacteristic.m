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

@end
