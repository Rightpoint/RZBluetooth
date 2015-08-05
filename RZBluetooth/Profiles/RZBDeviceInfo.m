//
//  CBPeripheral+RZBDeviceInfo.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDeviceInfo.h"
#import "CBPeripheral+RZBHelper.h"

NSString *const RZBDeviceInfoModelNumberKey = @"modelNumber";

@implementation RZBDeviceInfo

+ (CBUUID *)serviceUUID
{
    return [CBUUID UUIDWithString:@"180A"];
}

+ (NSDictionary *)characteristicUUIDsByKey
{
    return @{@"modelNumber"     : [CBUUID UUIDWithString:@"2a24"],
             @"serialNumber"    : [CBUUID UUIDWithString:@"2a25"],
             @"firmwareRevision": [CBUUID UUIDWithString:@"2a26"],
             @"hardwareRevision": [CBUUID UUIDWithString:@"2a27"],
             @"manufacturerName": [CBUUID UUIDWithString:@"2a29"],
             };
}

+ (CBCharacteristicProperties)characteristicPropertiesForKey:(NSString *)key
{
    return CBCharacteristicPropertyRead;
}

+ (id)valueForKey:(NSString *)key fromData:(NSData *)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSData *)dataForKey:(NSString *)key fromValue:(NSString *)value
{
    NSAssert([value isKindOfClass:[NSString class]], @"Unexpected value type %@", [value class]);
    return [value dataUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation CBPeripheral (RZBDeviceInfo)

- (void)rzb_fetchDeviceInformation:(NSArray *)deviceInfoKeys
                        completion:(RZBDeviceInfoCallback)completion
{
    NSDictionary *UUIDsByKey = [RZBDeviceInfo characteristicUUIDsByKey];
    deviceInfoKeys = deviceInfoKeys ?: [UUIDsByKey allKeys];
    RZBDeviceInfo *deviceInfo = [[RZBDeviceInfo alloc] init];
    __block NSError *lastError = nil;
    dispatch_group_t done = dispatch_group_create();
    for (NSString *key in deviceInfoKeys) {
        dispatch_group_enter(done);
        [self readCharacteristicUUID:UUIDsByKey[key]
                         serviceUUID:[RZBDeviceInfo serviceUUID]
                          completion:^(CBCharacteristic *characteristic, NSError *error) {
                              [deviceInfo setValue:[RZBDeviceInfo valueForKey:key fromData:characteristic.value] forKey:key];
                              BOOL isDiscoveryError = ([[error domain] isEqualToString:RZBluetoothErrorDomain] &&
                                                       [error code] == RZBluetoothDiscoverCharacteristicError);
                              if (error && isDiscoveryError == NO) {
                                  lastError = error;
                              }
                              dispatch_group_leave(done);
                          }];
    }
    dispatch_group_notify(done, self.queue, ^{
        completion(deviceInfo, lastError);
    });
}

@end
