//
//  RZBProfileDeviceInfoTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZBProfileTestCase.h"
#import "RZBSimulatedDevice.h"
#import "RZBDeviceInfo.h"
#import "RZBMockPeripheralManager.h"


@interface RZBProfileDeviceInfoTestCase : RZBProfileTestCase
@property (strong, nonatomic) RZBSimulatedDevice *device;
@property (strong, nonatomic) RZBDeviceInfo *deviceInfo;
@end

@implementation RZBProfileDeviceInfoTestCase

- (void)setUp {
    [super setUp];
    [self.mockCentralManager fakeStateChange:CBCentralManagerStatePoweredOn];
    self.device = [[RZBSimulatedDevice alloc] initWithSimulatedCentral:self.centralManager.simulatedCentral];
    self.deviceInfo = [[RZBDeviceInfo alloc] init];
    self.deviceInfo.manufacturerName = @"Fake Bytes";
    self.deviceInfo.serialNumber = @"1234567890";
    [self.device addBluetoothRepresentable:self.deviceInfo isPrimary:YES];
}

- (void)tearDown {
    self.device = nil;
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

- (void)testReadPopulatedCharacteristic
{
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformation:@[@"manufacturerName"] completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssert(self.deviceInfo != deviceInfo);
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];

}


@end
