//
//  RZBTestableCentralManager.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCentralManager.h"
@class RZBSimulatedCentral;
@class RZBMockCentralManager;

@interface RZBTestableCentralManager : RZBCentralManager

@property (strong, nonatomic, readonly) RZBSimulatedCentral *simulatedCentral;

- (RZBMockCentralManager *)mockCentralManager;

@end
