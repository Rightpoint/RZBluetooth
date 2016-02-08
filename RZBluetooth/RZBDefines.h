//
//  RZBDefines.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#define RZB_KEYPATH(c, p) ({\
c *object __unused; \
typeof(object.p) property __unused; \
@#p; \
})

#define RZB_OVERLOADED FOUNDATION_EXTERN __attribute__((overloadable))

NS_ASSUME_NONNULL_BEGIN

typedef void(^RZBScanBlock)(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI);
typedef void(^RZBErrorBlock)(NSError *__nullable error);
typedef void(^RZBStateBlock)(CBCentralManagerState state);
typedef void(^RZBRestorationBlock)(NSArray *peripherals);
typedef void(^RZBRSSIBlock)(NSNumber *RSSI, NSError *__nullable error);

typedef void(^RZBPeripheralBlock)(CBPeripheral *peripheral, NSError *__nullable error);
typedef void(^RZBServiceBlock)(CBService *service, NSError *__nullable error);
typedef void(^RZBCharacteristicBlock)(CBCharacteristic *characteristic, NSError *__nullable error);

NS_ASSUME_NONNULL_END

