//
//  RZBPeripheral+RZBHeartRate.h
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBPeripheral.h"
#import "RZBHeartRateMeasurement.h"

typedef void(^RZBHeartRateUpdateCompletion)(RZBHeartRateMeasurement *__nullable measurement, NSError *__nullable error);
typedef void(^RZBHeartRateSensorLocationCompletion)(RZBBodyLocation location);

NS_ASSUME_NONNULL_BEGIN

@interface RZBPeripheral (RZBHeartRate)

/**
 * Read the sensor location of the heart rate monitor. This callback will return Other if an
 * error occurs.
 */
- (void)readSensorLocation:(RZBHeartRateSensorLocationCompletion)completion;

- (void)addHeartRateObserver:(RZBHeartRateUpdateCompletion)update completion:(RZBErrorBlock __nullable)completion;

- (void)removeHeartRateObserver:(RZBErrorBlock)completion;

- (void)resetHeartRateEnergyExpended:(RZBErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
