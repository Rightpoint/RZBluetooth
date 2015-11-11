//
//  RZBSimulatedTests.m
//  RZBluetooth
//
//  Created by Brian King on 8/6/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"

@interface RZBSimulatedTests : RZBSimulatedTestCase

@end

@implementation RZBSimulatedTests

- (void)testScanForDevices
{
    XCTestExpectation *discovered = [self expectationWithDescription:@"Peripheral will connect"];

    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:nil
                                 onDiscoveredPeripheral:^(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI) {
                                     [discovered fulfill];
                                     XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
                                 }
                                             completion:nil];
    [self.device.peripheralManager startAdvertising:@{}];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [self.centralManager stopScan];
}

- (void)testConnection
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];

    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(CBPeripheral *peripheral, NSError *error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionError
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    self.connection.connectCallback.injectError = [NSError rzb_connectionError];
    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(CBPeripheral *peripheral, NSError *error) {
        [connected fulfill];
        XCTAssertNotNil(error);
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectable
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    CBPeripheral *p = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(CBPeripheral *peripheral, NSError *error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateConnecting);

    self.connection.connectable = YES;
    XCTAssert(p.state == CBPeripheralStateConnecting);

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssert(p.state == CBPeripheralStateConnected);
}

- (void)testConnectionAndCancelWhileNotConnectable
{
    XCTestExpectation *connectCallback = [self expectationWithDescription:@"Connect Callback"];
    XCTestExpectation *cancelConnectCallback = [self expectationWithDescription:@"Connect Cancelation Callback"];

    CBPeripheral *p = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(CBPeripheral *peripheral, NSError *error) {
        XCTAssertNil(peripheral);
        XCTAssertNil(error);
        [connectCallback fulfill];
    }];
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateConnecting);

    [self.centralManager cancelConnectionFromPeripheralUUID:self.device.identifier
                                                 completion:^(CBPeripheral *peripheral, NSError *error) {
                                                     XCTAssertNotNil(peripheral);
                                                     XCTAssertNil(error);
                                                     [cancelConnectCallback fulfill];
                                                 }];
    [self waitForQueueFlush];


    self.connection.connectable = YES;
    XCTAssert(p.state == CBPeripheralStateDisconnected);

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


@end
