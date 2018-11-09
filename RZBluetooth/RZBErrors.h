//
//  RZBErrors.h
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;
#import "RZBDefines.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const RZBluetoothErrorDomain;

typedef NS_ENUM(NSUInteger, RZBluetoothError) {
    /// See CBManagerStateUnsupported
    RZBluetoothUnsupported = CBManagerStateUnsupported,
    /// See CBManagerStateUnauthorized
    RZBluetoothUnauthorized = CBManagerStateUnauthorized,
    /// See CBManagerStatePoweredOff
    RZBluetoothPoweredOff = CBManagerStatePoweredOff,
    /// This error is generated if the user attempts to discover a service which does not exist.
    RZBluetoothDiscoverServiceError,
    /// This error is generated if the user attempts to discover a characteristic which does not exist.
    RZBluetoothDiscoverCharacteristicError,
    /// This error is generated if bluetooth does not respond to within RZBUserInteraction.timeout
    RZBluetoothTimeoutError,
    /// This error is generated if a notification is unsubscribed while the device is observing
    /// the characteristic. This behavior is only enabled if RZBPeripheral.notifyUnsubscription is true.
    RZBluetoothNotifyUnsubscribed,
    /// This error is generated if there are commands dispatched to the peripheral when the connection
    /// is cancelled.
    RZBluetoothConnectionCancelled
};

FOUNDATION_EXPORT NSString *const RZBluetoothUndiscoveredUUIDsKey;
FOUNDATION_EXPORT NSError *__nullable RZBluetoothErrorForState(CBManagerState state);

NS_ASSUME_NONNULL_END
