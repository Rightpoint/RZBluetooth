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
@class RZBSimulatedCentral;

@interface RZBSimulatedDevice : NSObject <CBPeripheralManagerDelegate>

- (instancetype)initWithSimulatedCentral:(RZBSimulatedCentral *)simulatedCentral;

@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (weak, nonatomic, readonly) RZBSimulatedCentral *simulatedCentral;
@property (strong, nonatomic, readonly) RZBMockPeripheralManager *peripheralManager;

- (void)addBluetoothRepresentable:(id<RZBBluetoothRepresentable>)bluetoothRepresentable isPrimary:(BOOL)isPrimary;

@end
