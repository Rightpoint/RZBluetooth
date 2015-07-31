//
//  RZBTestCentralManager.m
//  UMTSDK
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBTestCentralManager.h"

#import "RZBMockCentralManager.h"

@implementation RZBTestCentralManager

+ (Class)coreBluetoothCentralManagerClass
{
    return [RZBMockCentralManager class];
}

@end
