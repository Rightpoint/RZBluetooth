//
//  CBPeripheral+RZBDeviceInfo.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBBluetoothRepresentable.h"
#import "RZBPeripheral.h"

/// Object representing a Bluetooth System ID
/// (See https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.system_id.xml)
@interface RZBSystemId : NSObject

/// 40-bit Manufacturer-defined identifier
@property (assign, nonatomic) UInt64 manufacturerId;
/// 24-bit Organizationally Unique Identifier aka Company Identifier assigned by IEEE
@property (assign, nonatomic) UInt32 ouid;

@end

/// Options for RZBPnPId.vendorIdSource property
typedef enum _RZBVendorIdSource : UInt8 {
    /// Reserved for future use
    reserved = 0,
    /// Vendor ID is a Company Identifier assigned by Bluetooth SIG
    bluetoothSig = 1,
    /// Vendor ID is assigned by USB Implementer's Forum
    usbImplementersForum = 2
} RZBVendorIdSource;

/// Object representing a Bluetooth PnP ID
/// (See https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.pnp_id.xml)
@interface RZBPnPId : NSObject

/// 8-bit Vendor ID Source
@property (assign, nonatomic) RZBVendorIdSource vendorIdSource;
/// 16-bit Vendor identifier
@property (assign, nonatomic) UInt16 vendorId;
/// 16-bit Product identifier assigned by vendor
@property (assign, nonatomic) UInt16 productId;
/// 16-bit Product version number assigned by vendor
@property (assign, nonatomic) UInt16 productVersion;

@end

@interface RZBDeviceInfo : NSObject <RZBBluetoothRepresentable>

@property (copy, nonatomic) NSString *manufacturerName;
@property (copy, nonatomic) NSString *modelNumber;
@property (copy, nonatomic) NSString *serialNumber;
@property (copy, nonatomic) NSString *hardwareRevision;
@property (copy, nonatomic) NSString *firmwareRevision;
@property (copy, nonatomic) NSString *softwareRevision;

@property (strong, nonatomic) RZBSystemId  *systemId;
@property (readonly, nonatomic) NSString *systemIdString;

@property (strong, nonatomic) RZBPnPId     *pnpId;
@property (readonly, nonatomic) NSString *pnpIdString;

@end

typedef void(^RZBDeviceInfoCallback)(RZBDeviceInfo *deviceInfo, NSError *error);

@interface RZBPeripheral (RZBDeviceInfo)

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
