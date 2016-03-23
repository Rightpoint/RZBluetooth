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
                                 onDiscoveredPeripheral:^(RZBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI) {
                                     [discovered fulfill];
                                     XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
                                 }
                                             onError:nil];
    [self.device.peripheralManager startAdvertising:@{}];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [self.centralManager stopScan];
}

- (void)testConnection
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];

    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(RZBPeripheral *peripheral, NSError *error) {
        [connected fulfill];
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionError
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    self.connection.connectCallback.injectError = [NSError rzb_connectionError];
    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(RZBPeripheral *peripheral, NSError *error) {
        [connected fulfill];
        XCTAssertNotNil(error);
        XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectable
{
    XCTestExpectation *connected = [self expectationWithDescription:@"Peripheral will connect"];
    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(RZBPeripheral *peripheral, NSError *error) {
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

    RZBPeripheral *p = [self.centralManager peripheralForUUID:self.device.identifier];
    XCTAssert(p.state == CBPeripheralStateDisconnected);
    self.connection.connectable = NO;

    [self.centralManager connectToPeripheralUUID:self.device.identifier completion:^(RZBPeripheral *peripheral, NSError *error) {
        XCTAssertNil(peripheral);
        XCTAssertNil(error);
        [connectCallback fulfill];
    }];
    [self waitForQueueFlush];
    XCTAssert(p.state == CBPeripheralStateConnecting);

    [self.centralManager cancelConnectionFromPeripheralUUID:self.device.identifier
                                                 completion:^(RZBPeripheral *peripheral, NSError *error) {
                                                     XCTAssertNotNil(peripheral);
                                                     XCTAssertNil(error);
                                                     [cancelConnectCallback fulfill];
                                                 }];
    [self waitForQueueFlush];


    self.connection.connectable = YES;
    XCTAssert(p.state == CBPeripheralStateDisconnected);

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
            [self.centralManager cancelConnectionFromPeripheralUUID:p.identifier completion:nil];
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
