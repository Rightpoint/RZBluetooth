//
//  CBPeripheral+RZBBattery.h
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^RZBBatteryCompletion)(NSUInteger level, NSError *error);

@interface CBUUID (RZBBattery)

+ (CBUUID *)rzb_UUIDForBatteryService;
+ (CBUUID *)rzb_UUIDForBatteryLevelCharacteristic;

@end

@interface CBPeripheral (RZBBattery)

- (void)rzb_fetchBatteryLevel:(RZBBatteryCompletion)completion;

@end
