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
                                 onDiscoveredPeripheral:^(RZBScanInfo *scanInfo, NSError *error) {
                                     [discovered fulfill];
                                     XCTAssert([scanInfo.peripheral.identifier isEqual:self.device.identifier]);
                                 }];
    [self.device.peripheralManager startAdvertising:@{}];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [self.centralManager stopScan];
}

- (void)testConnection
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.device.identifier];
    [peripheral connectWithCompletion:^(RZBPeripheral * _Nullable p, NSError * _Nullable error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionError
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    self.connection.connectCallback.injectError = [NSError rzb_connectionError];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.device.identifier];
    [peripheral connectWithCompletion:^(RZBPeripheral * _Nullable p, NSError * _Nullable error) {
        [connected fulfill];
        XCTAssertNotNil(error);
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectable
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(peripheral.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [peripheral connectWithCompletion:^(RZBPeripheral * _Nullable p, NSError * _Nullable error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForQueueFlush];
    XCTAssert(peripheral.state == CBPeripheralStateConnecting);

    self.connection.connectable = YES;
    XCTAssert(peripheral.state == CBPeripheralStateConnecting);

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssert(peripheral.state == CBPeripheralStateConnected);
}

- (void)testConnectionAndCancelWhileNotConnectable
{
    XCTestExpectation *connectCallback = [self expectationWithDescription:@"Connect Callback"];
    XCTestExpectation *cancelConnectCallback = [self expectationWithDescription:@"Connect Cancelation Callback"];

    RZBPeripheral *peripheral = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(peripheral.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [peripheral connectWithCompletion:^(RZBPeripheral *p, NSError *error) {
        XCTAssertNil(p);
        XCTAssertNil(error);
        [connectCallback fulfill];
    }];
    [self waitForQueueFlush];
    XCTAssert(peripheral.state == CBPeripheralStateConnecting);

    [peripheral cancelConnectionWithCompletion:^(RZBPeripheral *p, NSError *error) {
        XCTAssertNotNil(p);
        XCTAssertNil(error);
        [cancelConnectCallback fulfill];
    }];
    [self waitForQueueFlush];


    self.connection.connectable = YES;
    XCTAssert(peripheral.state == CBPeripheralStateDisconnected);

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testMaintainConnection
{
    __block NSUInteger connectCount = 0;
    __block NSUInteger disconnectCount = 0;
    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    p.onConnection = ^(RZBPeripheral *peripheral, NSError *error) {
        connectCount++;
    };
    p.onDisconnection = ^(RZBPeripheral *peripheral, NSError *error) {
        disconnectCount++;
    };
    p.maintainConnection = YES;

#define TEST_COUNT 10
    for (NSUInteger i = 0; i < TEST_COUNT; i++) {
        [self waitForQueueFlush];
        XCTAssert(p.state == CBPeripheralStateConnecting);

        self.connection.connectable = YES;
        [self waitForQueueFlush];
        XCTAssert(p.state == CBPeripheralStateConnected);
        XCTAssert(connectCount == i + 1);

        // Disable the connection maintenance on the last iteration.
        if (i == TEST_COUNT - 1) {
            [p cancelConnectionWithCompletion:nil];
            // Cancel will clear out the disconnect block so it should not be triggered.
            [self waitForQueueFlush];
            XCTAssert(disconnectCount == i);
        }
        else {
            self.connection.connectable = NO;
            [self waitForQueueFlush];
            XCTAssert(disconnectCount == i + 1);
        }
    }
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
}

@end
