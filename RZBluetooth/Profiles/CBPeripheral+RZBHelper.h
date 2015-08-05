//
//  CBPeripheral+RZBHelper.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+RZBExtension.h"
#import "RZBErrors.h"

@class RZBCentralManager;

/**
 * Helper class for use by the various profiles.
 */
@interface CBPeripheral (RZBHelper)

@property (weak, nonatomic, readonly) RZBCentralManager *rzb_centralManager;
@property (weak, nonatomic, readonly) dispatch_queue_t rzb_queue;

@end
