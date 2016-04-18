//
//  RZBCentralManager+Mock.m
//  RZBluetooth
//
//  Created by Brian King on 3/28/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBCentralManager+Mock.h"
#import "RZBCentralManager+Private.h"
#import "RZBMockCentralManager.h"

@implementation RZBCentralManager (Mock)

- (RZBMockCentralManager *)mockCentralManager
{
    RZBMockCentralManager *mockCentralManager = (id)self.centralManager;
    NSAssert([mockCentralManager isKindOfClass:[RZBMockCentralManager class]], @"Must enable mocking to use this method");
    return mockCentralManager;
}

@end
