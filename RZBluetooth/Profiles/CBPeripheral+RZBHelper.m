//
//  CBPeripheral+RZBHelper.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+RZBHelper.h"
#import "RZBCentralManager+Private.h"

@implementation CBPeripheral (RZBHelper)

- (RZBCentralManager *)centralManager
{
    RZBCentralManager *centralManager = (id)self.delegate;
    NSAssert([centralManager isKindOfClass:[RZBCentralManager class]], @"CBPeripheral is not properly configured.  The delegate property must be configured to the RZCentralManager that owns it.");
    return centralManager;
}

- (dispatch_queue_t)queue
{
    return self.centralManager.dispatch.queue;
}

@end
