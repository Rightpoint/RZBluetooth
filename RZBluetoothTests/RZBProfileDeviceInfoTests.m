//
//  RZBProfileDeviceInfoTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"
#import "RZBDeviceInfo.h"

@interface RZBProfileDeviceInfoTests : RZBSimulatedTestCase
@property (strong, nonatomic) RZBDeviceInfo *deviceInfo;
@end

@implementation RZBProfileDeviceInfoTests

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

- (void)testReadSpecifiedCharacteristics
{
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformationKeys:@[@"manufacturerName"] completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssertNil(deviceInfo.serialNumber);
        XCTAssert(self.deviceInfo != deviceInfo);
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testReadAllCharacteristics
{
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformationKeys:nil completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssert([self.deviceInfo.serialNumber isEqualToString:deviceInfo.serialNumber]);
        XCTAssertNil(deviceInfo.modelNumber);
        XCTAssertNil(deviceInfo.hardwareRevision);
        XCTAssertNil(deviceInfo.firmwareRevision);
        XCTAssertNil(deviceInfo.softwareRevision);

        XCTAssert(self.deviceInfo != deviceInfo);
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
