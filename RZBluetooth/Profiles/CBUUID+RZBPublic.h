//
//  CBUUID+RZBPublic.h
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@interface CBUUID (RZBPublic)

+ (CBUUID *)rzb_UUIDForBatteryService;
+ (CBUUID *)rzb_UUIDForBatteryLevelCharacteristic;

+ (CBUUID *)rzb_UUIDForHeartRateService;
+ (CBUUID *)rzb_UUIDForHeartRateMeasurementCharacteristic;
+ (CBUUID *)rzb_UUIDForBodyLocationCharacteristic;
+ (CBUUID *)rzb_UUIDForHeartRateControlCharacteristic;

@end
