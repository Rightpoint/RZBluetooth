//
//  RZBSimulatedCentral.h
//  RZBluetooth
//
//  Created by Brian King on 7/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralManager.h"

@class RZBMockPeripheralManager;
@class RZBSimulatedConnection;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The simulated central is an internal object for managing the association of a connection and a peripheral
 *  manager.
 */
@interface RZBSimulatedCentral : NSObject <RZBMockCentralManagerDelegate>

- (instancetype)initWithMockCentralManager:(RZBMockCentralManager *)centralManager;

@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;
@property (nonatomic) NSUInteger maximumUpdateValueLength;

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralManager:(RZBMockPeripheralManager *)peripheralManager;

- (void)removeSimulatedDevice:(NSUUID *)peripheralUUID;

- (RZBSimulatedConnection *__nullable)connectionForIdentifier:(NSUUID *)identifier;

@end

NS_ASSUME_NONNULL_END
