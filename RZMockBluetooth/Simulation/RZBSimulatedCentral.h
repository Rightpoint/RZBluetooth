//
//  RZBSimulatedCentral.h
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockedCentralManager.h"
#import "RZBMockedPeripheralManager.h"

@class RZBSimulatedConnection;

/**
 *  The simulated central is an internal object for managing the association of a connection and a peripheral
 *  manager.
 */
@interface RZBSimulatedCentral : NSObject <RZBMockCentralManagerDelegate>

- (instancetype)initWithMockCentralManager:(id<RZBMockedCentralManager>)centralManager;

@property (strong, nonatomic, readonly) id<RZBMockedCentralManager>mockCentralManager;
@property (assign, nonatomic) NSUInteger maximumUpdateValueLength;

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralManager:(CBPeripheralManager<RZBMockedPeripheralManager> *)peripheralManager;

- (void)removeSimulatedDevice:(NSUUID *)peripheralUUID;

- (RZBSimulatedConnection *)connectionForIdentifier:(NSUUID *)identifier;

@end
