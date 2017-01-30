//
//  CBPeripheral+RZBDeviceInfo.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDeviceInfo.h"
#import "RZBErrors.h"

NSString *const RZBDeviceInfoModelNumberKey = @"modelNumber";

// MARK: -

const UInt64 kManufacturerIDMask    = 0x000000FFFFFFFFFF;
const UInt64 kOUIDMask              = 0xFFFFFF0000000000;
const int    kManufacturerIDShift   = 0;
const int    kOUIDShift             = 40;

@implementation RZBSystemId
@end

// MARK: -

@implementation RZBPnPId
@end

// MARK: -

@implementation RZBDeviceInfo

+ (CBUUID *)serviceUUID
{
    return [CBUUID UUIDWithString:@"180A"];
}

+ (NSDictionary *)characteristicUUIDsByKey
{
    return @{@"systemId"        : [CBUUID UUIDWithString:@"2a23"],
             @"modelNumber"     : [CBUUID UUIDWithString:@"2a24"],
             @"serialNumber"    : [CBUUID UUIDWithString:@"2a25"],
             @"firmwareRevision": [CBUUID UUIDWithString:@"2a26"],
             @"hardwareRevision": [CBUUID UUIDWithString:@"2a27"],
             @"softwareRevision": [CBUUID UUIDWithString:@"2a28"],
             @"manufacturerName": [CBUUID UUIDWithString:@"2a29"],
             @"pnpId"           : [CBUUID UUIDWithString:@"2a50"]
             };
}

+ (CBCharacteristicProperties)characteristicPropertiesForKey:(NSString *)key
{
    return CBCharacteristicPropertyRead;
}

+ (id)valueForKey:(NSString *)key fromData:(NSData *)data
{
    if ([key isEqualToString:@"systemId"]) {
        UInt64 bytes;
        [data getBytes:&bytes length:sizeof(bytes)];
        bytes = CFSwapInt64LittleToHost(bytes);
        RZBSystemId *systemId = [[RZBSystemId alloc] init];
        systemId.manufacturerId = ((bytes & kManufacturerIDMask) >> kManufacturerIDShift);
        systemId.ouid =   (UInt32)((bytes & kOUIDMask) >> kOUIDShift);
        return systemId;
    }
    else
    if ([key isEqualToString:@"pnpId"]) {
        RZBPnPId *pnpId = [[RZBPnPId alloc] init];
        RZBVendorIdSource rawVendorIdSource = reserved;
        UInt16 rawId = 0;
        int position = 0, len = sizeof(rawVendorIdSource);
        [data getBytes:&rawVendorIdSource range:NSMakeRange(position, len)];
        pnpId.vendorIdSource = rawVendorIdSource;
        
        position += len; len = sizeof(rawId);
        [data getBytes:&rawId range:NSMakeRange(position, len)];
        pnpId.vendorId = CFSwapInt16LittleToHost(rawId);
        
        position += len; len = sizeof(rawId);
        [data getBytes:&rawId range:NSMakeRange(position, len)];
        pnpId.productId = CFSwapInt16LittleToHost(rawId);

        position += len; len = sizeof(rawId);
        [data getBytes:&rawId range:NSMakeRange(position, len)];
        pnpId.productVersion = CFSwapInt16LittleToHost(rawId);
        
        return pnpId;
    }
    else {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

+ (NSData *)dataForKey:(NSString *)key fromValue:(id)value
{
    if ([key isEqualToString:@"systemId"]) {
        NSAssert([value isKindOfClass:[RZBSystemId class]], @"Unexpected value type %@", [value class]);
        RZBSystemId *systemId = (RZBSystemId *)value;
        UInt64 bytes;
        bytes  = (((UInt64)systemId.ouid << kOUIDShift) & kOUIDMask);
        bytes |= (((UInt64)systemId.manufacturerId << kManufacturerIDShift) & kManufacturerIDMask);
        bytes  = CFSwapInt64HostToLittle(bytes);
        return [NSData dataWithBytes:&bytes length:sizeof(bytes)];
    }
    else
    if ([key isEqualToString:@"pnpId"]) {
        NSAssert([value isKindOfClass:[RZBPnPId class]], @"Unexpected value type %@", [value class]);
        RZBPnPId *pnpId = (RZBPnPId *)value;
        NSMutableData *data = [NSMutableData data];
        
        RZBVendorIdSource rawVendorIdSource = pnpId.vendorIdSource;
        [data appendBytes:&rawVendorIdSource length:sizeof(rawVendorIdSource)];
        
        UInt16 rawId = CFSwapInt16HostToLittle(pnpId.vendorId);
        [data appendBytes:&rawId length:sizeof(rawId)];

        rawId = CFSwapInt16HostToLittle(pnpId.productId);
        [data appendBytes:&rawId length:sizeof(rawId)];

        rawId = CFSwapInt16HostToLittle(pnpId.productVersion);
        [data appendBytes:&rawId length:sizeof(rawId)];
        
        return data;
    }
    else {
        NSAssert([value isKindOfClass:[NSString class]], @"Unexpected value type %@", [value class]);
        return [(NSString*)value dataUsingEncoding:NSUTF8StringEncoding];
    }
}

- (NSString *)systemIdString
{
    return [NSString stringWithFormat:@"%06X-%010llX",
            self.systemId.ouid,
            self.systemId.manufacturerId
            ];
}

- (NSString *)pnpIdString
{
    return [NSString stringWithFormat:@"%d-%04X-%04X-%04X",
            self.pnpId.vendorIdSource,
            self.pnpId.vendorId,
            self.pnpId.productId,
            self.pnpId.productVersion
            ];
}

@end

// MARK: -

@implementation RZBPeripheral (RZBDeviceInfo)

- (void)rzb_fetchDeviceInformationKeys:(NSArray *)deviceInfoKeys
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
                              if (characteristic.value) {
                                  [deviceInfo setValue:[RZBDeviceInfo valueForKey:key fromData:characteristic.value] forKey:key];
                              }
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
