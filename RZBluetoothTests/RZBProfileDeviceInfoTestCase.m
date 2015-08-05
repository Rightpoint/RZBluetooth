//
//  RZBProfileDeviceInfoTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "RZBDeviceInfo.h"

@interface RZBProfileDeviceInfoTestCase : RZBSimulatedTestCase
@property (strong, nonatomic) RZBDeviceInfo *deviceInfo;
@end

@implementation RZBProfileDeviceInfoTestCase

- (void)setUp
{
    [super setUp];

    self.deviceInfo = [[RZBDeviceInfo alloc] init];
    self.deviceInfo.manufacturerName = @"Fake Bytes";
    self.deviceInfo.serialNumber = @"1234567890";
    [self.device addBluetoothRepresentable:self.deviceInfo isPrimary:YES];
}

- (void)tearDown
{
    self.deviceInfo = nil;
    [super tearDown];
}

- (CBPeripheral *)peripheral
{
    return [self.centralManager peripheralForUUID:self.device.identifier];
}

- (void)testScan
{
    XCTestExpectation *discovered = [self expectationWithDescription:@"Peripheral will connect"];

    [self.centralManager scanForPeripheralsWithServices:@[[RZBDeviceInfo serviceUUID]]
                                                options:nil
                                 onDiscoveredPeripheral:^(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI) {
                                     [discovered fulfill];
                                     XCTAssert([peripheral.identifier isEqual:self.device.identifier]);
                                 }];
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

- (void)testReadPopulatedCharacteristic
{
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformationKeys:@[@"manufacturerName"] completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssert(self.deviceInfo != deviceInfo);
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}


@end
