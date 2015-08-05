//
//  RZBTestableCentralManager.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBTestableCentralManager.h"
#import "RZBCentralManager+Private.h"
#import "RZBMockCentralManager.h"
#import "RZBSimulatedCentral.h"

@implementation RZBTestableCentralManager

- (instancetype)initWithIdentifier:(NSString *)identifier queue:(dispatch_queue_t)queue
{
    self = [self initWithIdentifier:identifier queue:queue centralClass:[RZBMockCentralManager class]];
    if (self) {
        _simulatedCentral = [[RZBSimulatedCentral alloc] initWithMockCentralManager:self.mockCentralManager];
    }
    return self;
}

- (RZBMockCentralManager *)mockCentralManager
{
    RZBMockCentralManager *mockCentral = (id)self.centralManager;
    NSAssert([mockCentral isKindOfClass:[RZBMockCentralManager class]], @"central manager is incorrect");
    return mockCentral;
}

@end
