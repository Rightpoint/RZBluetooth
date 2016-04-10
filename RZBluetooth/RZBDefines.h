//
//  RZBDefines.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;
#import "RZBPeripheralStateEvent.h"

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
typedef void(^RZBStateBlock)(CBCentralManagerState state);
typedef void(^RZBRestorationBlock)(NSArray<RZBPeripheral *> *peripherals);
typedef void(^RZBRSSIBlock)(NSNumber *__nullable RSSI, NSError *__nullable error);
typedef void(^RZBConnectionBlock)(RZBPeripheralStateEvent state, NSError *__nullable error);

typedef void(^RZBServiceBlock)(CBService *__nullable service, NSError *__nullable error);
typedef void(^RZBCharacteristicBlock)(CBCharacteristic *__nullable characteristic, NSError *__nullable error);

NS_ASSUME_NONNULL_END

