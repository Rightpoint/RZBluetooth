//
//  RZBPeripheral+RZBHeartRate.m
//  RZBluetooth
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "RZBPeripheral+RZBHeartRate.h"
#import "RZBPeripheral.h"
#import "RZBHeartRateMeasurement.h"
#import "CBUUID+RZBPublic.h"

typedef NS_ENUM(uint8_t, RZBHeartRateControl) {
    RZBHeartRateControlResetEnergyExpended = 1
};

@implementation RZBPeripheral (RZBHeartRate)

- (void)readSensorLocation:(RZBHeartRateSensorLocationCompletion)completion
{
    NSParameterAssert(completion);
    [self readCharacteristicUUID:[CBUUID rzb_UUIDForBodyLocationCharacteristic]
                     serviceUUID:[CBUUID rzb_UUIDForHeartRateService]
                      completion:^(CBCharacteristic *characteristic, NSError *error) {
                          RZBBodyLocation location = RZBBodyLocationOther;
                          [characteristic.value getBytes:&location length:sizeof(RZBBodyLocation)];
                          completion(location);
                      }];
}

- (void)addHeartRateObserver:(RZBHeartRateUpdateCompletion)update completion:(RZBErrorBlock)completion
{
    NSParameterAssert(update);
    RZB_DEFAULT_ERROR_BLOCK(completion);
    [self enableNotifyForCharacteristicUUID:[CBUUID rzb_UUIDForHeartRateMeasurementCharacteristic]
                                serviceUUID:[CBUUID rzb_UUIDForHeartRateService]
                                   onUpdate:^(CBCharacteristic *characteristic, NSError *error) {
                                       RZBHeartRateMeasurement *m = [[RZBHeartRateMeasurement alloc] initWithBluetoothData:characteristic.value];
                                       update(m, error);
                                   } completion:^(CBCharacteristic *characteristic, NSError *error) {
                                       completion(error);
                                   }];
}

- (void)removeHeartRateObserver:(RZBErrorBlock)completion
{
    RZB_DEFAULT_ERROR_BLOCK(completion);
    [self clearNotifyBlockForCharacteristicUUID:[CBUUID rzb_UUIDForHeartRateMeasurementCharacteristic]
                                    serviceUUID:[CBUUID rzb_UUIDForHeartRateService]
                                     completion:^(CBCharacteristic *characteristic, NSError *error) {
                                         completion(error);
                                     }];
}

- (void)resetHeartRateEnergyExpended:(RZBErrorBlock)completion
{
    RZB_DEFAULT_ERROR_BLOCK(completion);
    RZBHeartRateControl control = RZBHeartRateControlResetEnergyExpended;
    [self writeData:[NSData dataWithBytes:&control length:sizeof(RZBHeartRateControl)]
 characteristicUUID:[CBUUID rzb_UUIDForHeartRateControlCharacteristic]
        serviceUUID:[CBUUID rzb_UUIDForHeartRateService]
         completion:^(CBCharacteristic *characteristic, NSError *error) {
             completion(error);
         }];
}

@end
