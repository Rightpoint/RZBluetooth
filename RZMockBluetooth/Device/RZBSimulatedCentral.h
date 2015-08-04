//
//  RZBSimulatedCentral.h
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBMockCentralManager.h"

@class RZBMockPeripheralManager;
@class RZBSimulatedCallback;

@interface RZBSimulatedCentral : NSObject <RZBMockCentralManagerDelegate>

+ (RZBSimulatedCentral *)shared;

- (void)addSimulatedDevice:(RZBMockPeripheralManager *)device;
- (void)removeSimulatedDevice:(RZBMockPeripheralManager *)device;

@property (assign, nonatomic) NSUInteger maximumUpdateValueLength;

@property (strong, nonatomic) RZBSimulatedCallback *scanCallback;
@property (strong, nonatomic) RZBSimulatedCallback *connectCallback;
@property (strong, nonatomic) RZBSimulatedCallback *cancelConncetionCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverServiceCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverCharacteristicCallback;

@property (strong, nonatomic) RZBSimulatedCallback *readCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *writeCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *notifyCharacteristicCallback;


@end
