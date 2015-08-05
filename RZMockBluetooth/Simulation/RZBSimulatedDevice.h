//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBDefines.h"

@class RZBMockPeripheralManager;

@interface RZBSimulatedDevice : NSObject <CBPeripheralManagerDelegate>

- (instancetype)initWithQueue:(dispatch_queue_t)queue options:(NSDictionary *)options peripheralManagerClass:(Class)peripheralManagerClass;

@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (strong, nonatomic, readonly) CBPeripheralManager *peripheralManager;

- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary;

@end
