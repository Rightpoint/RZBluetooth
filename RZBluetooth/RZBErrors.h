//
//  RZBErrors.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

FOUNDATION_EXPORT NSString *const RZBluetoothErrorDomain;

typedef NS_ENUM(NSUInteger, RZBluetoothError) {
    RZBluetoothUnsupported = CBCentralManagerStateUnsupported,
    RZBluetoothUnauthorized = CBCentralManagerStateUnauthorized,
    RZBluetoothPoweredOff = CBCentralManagerStatePoweredOff,
    RZBluetoothDiscoverServiceError,
    RZBluetoothDiscoverCharacteristicError,

};

FOUNDATION_EXPORT NSString *const RZBluetoothUndiscoveredUUIDsKey;
