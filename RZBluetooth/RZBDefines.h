//
//  RZBDefines.h
//  RZBluetooth
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;
#import "RZBPeripheralStateEvent.h"

#if (TARGET_OS_IOS && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0) || \
    (TARGET_OS_TV && __TV_OS_VERSION_MIN_REQUIRED < __TVOS_10_0) || \
    (TARGET_OS_WATCH && __WATCH_OS_VERSION_MIN_REQUIRED < __WATCHOS_3_0) || \
    (TARGET_OS_OSX && MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_13)
#define CBManagerState CBCentralManagerState
#define CBManagerStateUnknown CBCentralManagerStateUnknown
#define CBManagerStateResetting CBCentralManagerStateResetting
#define CBManagerStatePoweredOn CBCentralManagerStatePoweredOn
#define CBManagerStateUnsupported CBCentralManagerStateUnsupported
#define CBManagerStateUnauthorized CBCentralManagerStateUnauthorized
#define CBManagerStatePoweredOff CBCentralManagerStatePoweredOff
#endif

@class RZBPeripheral;
@class RZBScanInfo;
#define RZB_KEYPATH(c, p) ({\
c *object __unused; \
typeof(object.p) property __unused; \
@#p; \
})

#define RZB_OVERLOADED FOUNDATION_EXTERN __attribute__((overloadable))
#define RZB_DEFAULT_BLOCK(block) block = block ?: ^(id obj, NSError *error) {}
#define RZB_DEFAULT_ERROR_BLOCK(block) block = block ?: ^(NSError *error) {}

NS_ASSUME_NONNULL_BEGIN

typedef void(^RZBScanBlock)(RZBScanInfo *__nullable scanInfo, NSError *__nullable error);
typedef void(^RZBErrorBlock)(NSError *__nullable error);
typedef void(^RZBStateBlock)(CBManagerState state);
typedef void(^RZBRestorationBlock)(NSArray<RZBPeripheral *> *peripherals);
typedef void(^RZBRSSIBlock)(NSNumber *__nullable RSSI, NSError *__nullable error);
typedef void(^RZBConnectionBlock)(RZBPeripheralStateEvent state, NSError *__nullable error);

typedef void(^RZBServiceBlock)(CBService *__nullable service, NSError *__nullable error);
typedef void(^RZBCharacteristicBlock)(CBCharacteristic *__nullable characteristic, NSError *__nullable error);

NS_ASSUME_NONNULL_END

