//
//  RZBProfileDeviceInfoTestCase.m
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBSimulatedTestCase.h"

@interface RZBProfileDeviceInfoTests : RZBSimulatedTestCase
@property (strong, nonatomic) RZBDeviceInfo *deviceInfo;
@end

@implementation RZBProfileDeviceInfoTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    self.deviceInfo = nil;
    [super tearDown];
}

// MARK: - Helper methods

- (RZBDeviceInfo *)partialDeviceInfo
{
    RZBDeviceInfo *deviceInfo = [[RZBDeviceInfo alloc] init];
    deviceInfo.manufacturerName    = @"Fake Bytes";
    deviceInfo.serialNumber        = @"1234567890";
    return deviceInfo;
}

- (RZBDeviceInfo *)fullDeviceInfo
{
    RZBSystemId *systemId = [[RZBSystemId alloc] init];
    systemId.ouid           =  0x000102;
    systemId.manufacturerId =  0x0304050607;
    
    RZBPnPId *pnpId = [[RZBPnPId alloc] init];
    pnpId.vendorIdSource = RZBVendorIdSourceBluetoothSig;
    pnpId.vendorId       = 0x0123;
    pnpId.productId      = 0x0456;
    pnpId.productVersion = 0x0789;
    
    RZBDeviceInfo *deviceInfo = [[RZBDeviceInfo alloc] init];
    deviceInfo.manufacturerName    = @"Fake Bytes";
    deviceInfo.modelNumber         = @"101";
    deviceInfo.serialNumber        = @"1234567890";
    deviceInfo.hardwareRevision    = @"HW v1.0";
    deviceInfo.firmwareRevision    = @"FW v2.0";
    deviceInfo.softwareRevision    = @"SW v3.0";
    deviceInfo.systemId            = systemId;
    deviceInfo.pnpId               = pnpId;
    return deviceInfo;
}

// MARK: - Reading Device Info test cases

- (void)testReadSpecifiedCharacteristics
{
    self.deviceInfo = [self partialDeviceInfo];
    [self.device addBluetoothRepresentable:self.deviceInfo isPrimary:YES];
    
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformationKeys:@[@"manufacturerName"] completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssertNil(deviceInfo.serialNumber);
        XCTAssert(self.deviceInfo != deviceInfo);
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testReadPartialCharacteristics
{
    self.deviceInfo = [self partialDeviceInfo];
    [self.device addBluetoothRepresentable:self.deviceInfo isPrimary:YES];
    
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformationKeys:nil completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssert([self.deviceInfo.serialNumber isEqualToString:deviceInfo.serialNumber]);
        XCTAssertNil(deviceInfo.modelNumber);
        XCTAssertNil(deviceInfo.hardwareRevision);
        XCTAssertNil(deviceInfo.firmwareRevision);
        XCTAssertNil(deviceInfo.softwareRevision);
        
        XCTAssertNil(deviceInfo.systemId);
        XCTAssertNil(deviceInfo.pnpId);
        
        XCTAssert([deviceInfo.systemIdString isEqualToString:@""]);
        XCTAssert([deviceInfo.pnpIdString isEqualToString:@""]);

        XCTAssert(self.deviceInfo != deviceInfo);
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testReadFullCharacteristics
{
    self.deviceInfo = [self fullDeviceInfo];
    [self.device addBluetoothRepresentable:self.deviceInfo isPrimary:YES];
    
    XCTestExpectation *read = [self expectationWithDescription:@"Peripheral will connect"];
    [self.peripheral rzb_fetchDeviceInformationKeys:nil completion:^(RZBDeviceInfo *deviceInfo, NSError *error) {
        [read fulfill];
        XCTAssert([self.deviceInfo.manufacturerName isEqualToString:deviceInfo.manufacturerName]);
        XCTAssert([self.deviceInfo.serialNumber     isEqualToString:deviceInfo.serialNumber]);
        XCTAssert([self.deviceInfo.modelNumber      isEqualToString:deviceInfo.modelNumber]);
        XCTAssert([self.deviceInfo.hardwareRevision isEqualToString:deviceInfo.hardwareRevision]);
        XCTAssert([self.deviceInfo.firmwareRevision isEqualToString:deviceInfo.firmwareRevision]);
        XCTAssert([self.deviceInfo.softwareRevision isEqualToString:deviceInfo.softwareRevision]);
        
        XCTAssert(self.deviceInfo.systemId.ouid == deviceInfo.systemId.ouid);
        XCTAssert(self.deviceInfo.systemId.manufacturerId == deviceInfo.systemId.manufacturerId);
        XCTAssert([self.deviceInfo.systemIdString isEqualToString:deviceInfo.systemIdString]);
        XCTAssert([self.deviceInfo.systemIdString isEqualToString:@"000102-0304050607"]);
        
        XCTAssert(self.deviceInfo.pnpId.vendorIdSource      == deviceInfo.pnpId.vendorIdSource);
        XCTAssert(self.deviceInfo.pnpId.vendorId            == deviceInfo.pnpId.vendorId);
        XCTAssert(self.deviceInfo.pnpId.productId           == deviceInfo.pnpId.productId);
        XCTAssert(self.deviceInfo.pnpId.productVersion      == deviceInfo.pnpId.productVersion);
        XCTAssert([self.deviceInfo.pnpIdString isEqualToString:deviceInfo.pnpIdString]);
        XCTAssert([self.deviceInfo.pnpIdString isEqualToString:@"1-0123-0456-0789"]);
        
        XCTAssert(self.deviceInfo != deviceInfo);
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
