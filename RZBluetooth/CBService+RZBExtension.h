//
//  CBService+RZBExtension.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (RZBExtension)

- (CBService * __nullable)rzb_serviceForUUID:(CBUUID *)serviceUUID;

@end

@interface CBService (RZBExtension)

- (CBCharacteristic * __nullable)rzb_characteristicForUUID:(CBUUID *)characteristicUUID;

@end

@interface CBMutableService (RZBExtension)

- (CBMutableCharacteristic * __nullable)rzb_characteristicForUUID:(CBUUID *)characteristicUUID;

@end

NS_ASSUME_NONNULL_END
