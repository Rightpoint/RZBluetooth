//
//  RZBPeripheral+RZBHeartRate.h
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBPeripheral.h"
#import "RZBHeartRateMeasurement.h"

typedef void(^RZBHeartRateCompletion)(NSError *error);
typedef void(^RZBHeartRateUpdateCompletion)(RZBHeartRateMeasurement *measurement, NSError *error);
typedef void(^RZBHeartRateSensorLocationCompletion)(RZBBodyLocation location);

@interface RZBPeripheral (RZBHeartRate)

/**
 * Read the sensor location of the heart rate monitor. This callback will return Other if an
 * error occurs.
 */
- (void)readSensorLocation:(RZBHeartRateSensorLocationCompletion)completion;

- (void)addHeartRateObserver:(RZBHeartRateUpdateCompletion)update completion:(RZBHeartRateCompletion)completion;

- (void)removeHeartRateObserver:(RZBHeartRateCompletion)completion;

- (void)resetHeartRateEnergyExpended:(RZBHeartRateCompletion)completion;

@end
