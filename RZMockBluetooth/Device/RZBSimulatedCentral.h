//
//  RZBSimulatedCentral.h
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBMockCentralManager.h"

@class RZBSimulatedDevice;

@interface RZBSimulatedCentral : NSObject <RZBMockCentralManagerDelegate>

+ (RZBSimulatedCentral *)shared;

- (void)addSimulatedDevice:(RZBSimulatedDevice *)device;

@end
