//
//  RZBPeripheral+RZBBattery.h
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RZBPeripheral.h"

typedef void(^RZBBatteryReadCompletion)(NSUInteger level, NSError *error);
typedef void(^RZBBatteryCompletion)(NSError *error);

@interface RZBPeripheral (RZBBattery)

- (void)fetchBatteryLevel:(RZBBatteryReadCompletion)completion;
- (void)addBatteryLevelObserver:(RZBBatteryReadCompletion)update completion:(RZBBatteryCompletion)completion;
- (void)removeBatteryLevelObserver:(RZBBatteryCompletion)completion;

@end
