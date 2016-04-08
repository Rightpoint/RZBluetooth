//
//  RZBSimulatedDevice.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

#import "RZBMockedPeripheral.h"
#import "RZBMockedPeripheralManager.h"

@class RZBSimulatedCallback;
@class RZBSimulatedCentral;
@class CBATTRequest;

/**
 *  A simulated connection controls the interactions between a peripheral manager 
 *  and the client facing CBPeripheral.
 *
 *  For simple integration testing, usually just the RSSI and connectable are required.
 *
 *  Look into the RZBSimulatedCallback API to inject delay or errors to specific callback methods.
 */
@interface RZBSimulatedConnection : NSObject <RZBMockPeripheralDelegate, RZBMockPeripheralManagerDelegate>

/**
 *  The identifier of the associated peripheral
 */
@property (strong, nonatomic, readonly) NSUUID *identifier;

/**
 *  The RSSI to simulate for the peripheral.
 */
@property (strong, nonatomic) NSNumber *RSSI;

/**
 *  A boolean to model the connected state to the peripheral.
 */
@property (assign, nonatomic) BOOL connectable;

- (void)disconnect;

@property (strong, nonatomic) RZBSimulatedCallback *scanCallback;
@property (strong, nonatomic) RZBSimulatedCallback *cancelConncetionCallback;
@property (strong, nonatomic) RZBSimulatedCallback *connectCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverServiceCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *readRSSICallback;
@property (strong, nonatomic) RZBSimulatedCallback *readCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *writeCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *notifyCharacteristicCallback;

@end
