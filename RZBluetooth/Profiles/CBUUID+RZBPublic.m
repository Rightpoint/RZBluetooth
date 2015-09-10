//
//  CBUUID+RZBPublic.m
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "CBUUID+RZBPublic.h"

@implementation CBUUID (RZBPublic)

+ (CBUUID *)rzb_UUIDForBatteryService
{
    return [CBUUID UUIDWithString:@"180F"];
}

+ (CBUUID *)rzb_UUIDForBatteryLevelCharacteristic
{
    return [CBUUID UUIDWithString:@"2A19"];
}

+ (CBUUID *)rzb_UUIDForHeartRateService
{
    return [CBUUID UUIDWithString:@"180D"];
}

+ (CBUUID *)rzb_UUIDForHeartRateMeasurementCharacteristic
{
    return [CBUUID UUIDWithString:@"2A37"];
}

+ (CBUUID *)rzb_UUIDForBodyLocationCharacteristic
{
    return [CBUUID UUIDWithString:@"2A38"];
}

+ (CBUUID *)rzb_UUIDForHeartRateControlCharacteristic
{
    return [CBUUID UUIDWithString:@"2A39"];
}

@end
