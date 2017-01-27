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
        case CBManagerStateUnknown:
        case CBManagerStateResetting:
        case CBManagerStatePoweredOn:
            break;
        case CBManagerStateUnsupported:
            error = [NSError errorWithDomain:RZBluetoothErrorDomain code:RZBluetoothUnsupported userInfo:nil];
            break;
        case CBManagerStateUnauthorized:
            error = [NSError errorWithDomain:RZBluetoothErrorDomain code:RZBluetoothUnauthorized userInfo:nil];
            break;
        case CBManagerStatePoweredOff:
            error = [NSError errorWithDomain:RZBluetoothErrorDomain code:RZBluetoothPoweredOff userInfo:nil];
            break;
    }
    return error;
}
