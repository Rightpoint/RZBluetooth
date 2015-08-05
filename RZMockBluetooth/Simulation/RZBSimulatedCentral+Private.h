//
//  RZBSimulatedCentral+Private.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedCentral.h"

@interface RZBSimulatedCentral ()

- (instancetype)initWithMockCentralManager:(RZBMockCentralManager *)centralManager;

@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;

- (void)triggerScanIfNeeded;

@end