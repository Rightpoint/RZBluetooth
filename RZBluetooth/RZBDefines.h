//
//  RZBDefines.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^RZBScanBlock)(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI);
typedef void(^RZBCentralManagerStateChangeBlock)(CBCentralManagerState state);

typedef void(^RZBPeripheralBlock)(CBPeripheral *peripheral, NSError *error);
typedef void(^RZBServiceBlock)(CBService *service, NSError *error);
typedef void(^RZBCharacteristicBlock)(CBCharacteristic *characteristic, NSError *error);

@protocol RZBBluetoothRepresentable <NSObject>

+ (CBUUID *)serviceUUID;
+ (NSDictionary *)characteristicUUIDsByKey;
+ (CBCharacteristicProperties)characteristicPropertiesForKey:(NSString *)key;
+ (id)valueForKey:(NSString *)key fromData:(NSData *)data;
+ (NSData *)dataForKey:(NSString *)key fromValue:(NSString *)value;

- (id)valueForKey:(NSString *)key;

@end
