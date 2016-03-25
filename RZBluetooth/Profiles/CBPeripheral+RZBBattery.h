//
//  RZBPeripheral+RZBBattery.h
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RZBPeripheral.h"

typedef void(^RZBBatteryReadCompletion)(NSUInteger level, NSError * __nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface RZBPeripheral (RZBBattery)

- (void)fetchBatteryLevel:(RZBBatteryReadCompletion)completion;
- (void)addBatteryLevelObserver:(RZBBatteryReadCompletion)update completion:(RZBErrorBlock __nullable)completion;
- (void)removeBatteryLevelObserver:(RZBErrorBlock __nullable)completion;

@end

NS_ASSUME_NONNULL_END