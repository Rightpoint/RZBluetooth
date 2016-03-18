//
//  RZBErrors.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const RZBluetoothErrorDomain;

typedef NS_ENUM(NSUInteger, RZBluetoothError) {
    RZBluetoothUnsupported = CBCentralManagerStateUnsupported,
    RZBluetoothUnauthorized = CBCentralManagerStateUnauthorized,
    RZBluetoothPoweredOff = CBCentralManagerStatePoweredOff,
    RZBluetoothDiscoverServiceError,
    RZBluetoothDiscoverCharacteristicError,
    RZBluetoothTimeoutError,
};

FOUNDATION_EXPORT NSString *const RZBluetoothUndiscoveredUUIDsKey;
FOUNDATION_EXPORT NSError *RZBluetoothErrorForState(CBCentralManagerState state);

NS_ASSUME_NONNULL_END
