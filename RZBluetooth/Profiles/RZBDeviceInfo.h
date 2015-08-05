//
//  CBPeripheral+RZBDeviceInfo.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

@interface RZBDeviceInfo : NSObject <RZBBluetoothRepresentable>

@property (copy, nonatomic) NSString *manufacturerName;
@property (copy, nonatomic) NSString *modelNumber;
@property (copy, nonatomic) NSString *serialNumber;
@property (copy, nonatomic) NSString *hardwareRevision;
@property (copy, nonatomic) NSString *firmwareRevision;
@property (copy, nonatomic) NSString *softwareRevision;

@end

typedef void(^RZBDeviceInfoCallback)(RZBDeviceInfo *deviceInfo, NSError *error);

@interface CBPeripheral (RZBDeviceInfo)

/**
 * Fetch the device information keys specified in deviceInfoKeys. If nil
 * is specified, all device info keys in RZBDeviceInfo are queried.
 * If the characteristic for the key is not found, the value will be nil.
 *
 * If any of the bluetooth commands fail for a non-characteristic-discovery reason
 * the last error will be reported to the completion block.
 */
- (void)rzb_fetchDeviceInformationKeys:(NSArray *)deviceInfoKeys
                            completion:(RZBDeviceInfoCallback)completion;

@end
