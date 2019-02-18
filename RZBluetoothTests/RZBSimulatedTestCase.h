//
//  RZBSimulatedTestCase.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import XCTest;

#import "RZBluetooth/RZBluetooth.h"
#import "RZBluetooth/RZMockBluetooth.h"

/**
 *  The RZBSimulatedTestCase is a convience class to assist testing bluetooth code.
 */
@interface RZBSimulatedTestCase : XCTestCase

@property (strong, nonatomic) RZBCentralManager *centralManager;
@property (strong, nonatomic, readonly) RZBPeripheral *peripheral;
@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;

@property (strong, nonatomic) RZBSimulatedCentral *central;
@property (strong, nonatomic) RZBSimulatedDevice *device;
@property (strong, nonatomic) RZBSimulatedConnection *connection;

/**
 * Over-ride in a test subclass to use a specific RZBSimulatedDevice subclass
 */
+ (Class)simulatedDeviceClass;

/**
 * Over-ride in a test subclass to instantiate RZBCentralManager
 */
- (void)configureCentralManager;


- (void)waitForQueueFlush;

@end
