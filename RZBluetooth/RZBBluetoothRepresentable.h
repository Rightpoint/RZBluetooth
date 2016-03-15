//
//  RZBBluetoothRepresentable.h
//  RZBluetooth
//
//  Created by Brian King on 2/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@protocol RZBBluetoothRepresentable <NSObject>

+ (CBUUID *)serviceUUID;
+ (NSDictionary *)characteristicUUIDsByKey;
+ (CBCharacteristicProperties)characteristicPropertiesForKey:(NSString *)key;
+ (id)valueForKey:(NSString *)key fromData:(NSData *)data;
+ (NSData *)dataForKey:(NSString *)key fromValue:(NSString *)value;

- (id)valueForKey:(NSString *)key;

@end
