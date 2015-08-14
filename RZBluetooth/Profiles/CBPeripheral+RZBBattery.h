//
//  CBPeripheral+RZBBattery.h
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^RZBBatteryReadCompletion)(NSUInteger level, NSError *error);
typedef void(^RZBBatteryCompletion)(NSError *error);

@interface CBUUID (RZBBattery)


@end

@interface CBPeripheral (RZBBattery)

- (void)rzb_fetchBatteryLevel:(RZBBatteryReadCompletion)completion;
- (void)rzb_addBatteryLevelObserver:(RZBBatteryReadCompletion)update completion:(RZBBatteryCompletion)completion;
- (void)rzb_removeBatteryLevelObserver:(RZBBatteryCompletion)completion;

@end
