//
//  RZBProfileTestCase.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import XCTest;

#import "RZBTestableCentralManager.h"
#import "RZBCentralManager+Private.h"
#import "RZBMockCentralManager.h"
#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedDevice.h"
#import "RZBMockPeripheralManager.h"
#import "RZBSimulatedCentral.h"
#import "RZBSimulatedConnection.h"
#import "RZBSimulatedCallback.h"
#import "NSError+RZBMock.h"

#define RZBAssertCommandCount(cnt) XCTAssert(self.centralManager.dispatch.commands.count == cnt, @"Expected %zd commands, saw %zd", cnt, self.centralManager.dispatch.commands.count)

@interface RZBSimulatedTestCase : XCTestCase

+ (Class)simulatedDeviceClass;

@property (strong, nonatomic) RZBTestableCentralManager *centralManager;
@property (strong, nonatomic, readonly) CBPeripheral *peripheral;
@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;
@property (strong, nonatomic) RZBSimulatedDevice *device;
@property (strong, nonatomic) RZBSimulatedConnection *connection;

- (void)waitForQueueFlush;

@end
