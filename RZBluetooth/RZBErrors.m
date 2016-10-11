//
//  RZBErrors.m
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBErrors.h"

NSString *const RZBluetoothErrorDomain = @"com.raizlabs.bluetooth";
NSString *const RZBluetoothUndiscoveredUUIDsKey = @"undiscoveredUUIDs";

NSError *RZBluetoothErrorForState(CBManagerState state)
{
    NSError *error = nil;
    switch (state) {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStatePoweredOn:
            break;
        case CBCentralManagerStateUnsupported:
            error = [NSError errorWithDomain:RZBluetoothErrorDomain code:RZBluetoothUnsupported userInfo:nil];
            break;
        case CBCentralManagerStateUnauthorized:
            error = [NSError errorWithDomain:RZBluetoothErrorDomain code:RZBluetoothUnauthorized userInfo:nil];
            break;
        case CBCentralManagerStatePoweredOff:
            error = [NSError errorWithDomain:RZBluetoothErrorDomain code:RZBluetoothPoweredOff userInfo:nil];
            break;
    }
    return error;
}
