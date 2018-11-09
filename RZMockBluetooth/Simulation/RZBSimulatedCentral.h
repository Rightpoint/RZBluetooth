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
 *  The simulated central manages the association between a central manager and
 *  a peripheral manager. This is the primary interface to the RZMockBluetooth
 *  simulation.
 */
@interface RZBSimulatedCentral : NSObject <RZBMockCentralManagerDelegate>

/**
 *  Create a new simulated central connected to the specified RZBMockCentralManager.
 *  This RZBMockCentralManager should be used in the application code in place of the
 *  CBCentralManager.
 */
- (instancetype)initWithMockCentralManager:(RZBMockCentralManager *)centralManager;

/**
 *  The represented mock central manager.
 */
@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;

/**
 *  A check to see if all of the connections in the simulated central are idle.
 */
@property (readonly) BOOL idle;

/**
 *  Return all of the connections associated with the central.
 */
@property (strong, nonatomic, readonly) NSMutableArray *connections;

/**
 *  Add a simulated device with the specified peripheralUUID and connect it to the
 *  specified peripheralManager.
 */
- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralManager:(RZBMockPeripheralManager *)peripheralManager;

/**
 *  Add a simulated device with the specified peripheralUUID, peripheralName and connect it to the
 *  specified peripheralManager.
 */

- (void)addSimulatedDeviceWithIdentifier:(NSUUID *)peripheralUUID peripheralName:(NSString *)name peripheralManager:(RZBMockPeripheralManager *)peripheralManager;

/**
 * Remove the simulated device associated with peripheralUUID.
 */
- (void)removeSimulatedDevice:(NSUUID *)peripheralUUID;

/**
 *  Return the RZBSimulatedConnection specified by identifier. This will return nil
 *  if the identifier was not added to the central.
 */
- (RZBSimulatedConnection *__nullable)connectionForIdentifier:(NSUUID *)identifier;

@end

NS_ASSUME_NONNULL_END
