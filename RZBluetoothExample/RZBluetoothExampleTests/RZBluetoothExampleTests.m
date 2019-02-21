//
//  RZBluetoothExampleTests.m
//  RZBluetoothExampleTests
//
//  Created by Matthew Lorentz on 2/20/19.
//  Copyright © 2019 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RZBluetoothTest/RZBSimulatedTestCase.h"

@interface RZBluetoothExampleTests : RZBSimulatedTestCase;
@property (strong, nonatomic) RZBDeviceInfo *deviceInfo;
@end

@implementation RZBluetoothExampleTests

- (void)testConnection
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.connection.identifier];
    [peripheral connectWithCompletion:^(NSError * _Nullable error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.connection.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
