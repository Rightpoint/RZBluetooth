//
//  RZBErrors.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const RZBluetoothErrorDomain;

typedef NS_ENUM(NSUInteger, RZBluetoothError) {
    RZBluetoothDiscoverServiceError = 1,
    RZBluetoothDiscoverCharacteristicError,
};

FOUNDATION_EXPORT NSString *const RZBluetoothUndiscoveredUUIDsKey;
