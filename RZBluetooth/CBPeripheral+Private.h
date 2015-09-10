//
//  CBPeripheral+Private.h
//  RZBluetooth
//
//  Created by Brian King on 9/10/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheral+RZBExtension.h"
#import "RZBCentralManager.h"

@interface CBPeripheral ()

@property (weak, nonatomic, readonly) RZBCentralManager *rzb_centralManager;
@property (weak, nonatomic, readonly) dispatch_queue_t rzb_queue;

@end
