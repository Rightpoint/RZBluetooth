//
//  CBPeripheral+RZBHeartRate.h
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;
#import "RZBHeartRateMeasurement.h"

typedef void(^RZBHeartRateCompletion)(NSError *error);
typedef void(^RZBHeartRateUpdateCompletion)(RZBHeartRateMeasurement *measurement, NSError *error);
typedef void(^RZBHeartRateSensorLocationCompletion)(RZBBodyLocation location);

@interface CBPeripheral (RZBHeartRate)

/**
 * Read the sensor location of the heart rate monitor. This callback will return Other if an
 * error occurs.
 */
- (void)rzb_readSensorLocation:(RZBHeartRateSensorLocationCompletion)completion;

- (void)rzb_addHeartRateObserver:(RZBHeartRateUpdateCompletion)update completion:(RZBHeartRateCompletion)completion;

- (void)rzb_removeHeartRateObserver:(RZBHeartRateCompletion)completion;

- (void)rzb_resetHeartRateEnergyExpended:(RZBHeartRateCompletion)completion;

@end
