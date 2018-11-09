//
//  RZBUUIDPathTests.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import XCTest;

#import "RZBUUIDPath.h"

@interface RZBUUIDPathTests : XCTestCase

@end

@implementation RZBUUIDPathTests

- (void)testAsserts
{
    NSUUID *nsUUID = [NSUUID UUID];
    CBUUID *cbUUID = [CBUUID UUIDWithString:@"01234567"];
    XCTAssertThrows(RZBUUIDP(nil));
    XCTAssertNoThrow(RZBUUIDP(nsUUID));

    XCTAssertThrows(RZBUUIDP(nil, cbUUID));
    XCTAssertThrows(RZBUUIDP(nsUUID, nil));
    XCTAssertNoThrow(RZBUUIDP(nsUUID, cbUUID));

    XCTAssertThrows(RZBUUIDP(nil, cbUUID, cbUUID));
    XCTAssertThrows(RZBUUIDP(nsUUID, nil, cbUUID));
    XCTAssertThrows(RZBUUIDP(nsUUID, cbUUID, nil));
    XCTAssertNoThrow(RZBUUIDP(nsUUID, cbUUID, cbUUID));
}

- (void)testProperties
{
    NSUUID *nsUUID = [NSUUID UUID];
    CBUUID *sUUID = [CBUUID UUIDWithString:@"01234567"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"12345678"];

    RZBUUIDPath *pUUIDPath = RZBUUIDP(nsUUID);
    XCTAssert(pUUIDPath.length == 1);
    XCTAssertEqualObjects(pUUIDPath.peripheralUUID, nsUUID);
    XCTAssertNil(pUUIDPath.serviceUUID);
    XCTAssertNil(pUUIDPath.characteristicUUID);

    RZBUUIDPath *sUUIDPath = RZBUUIDP(nsUUID, sUUID);
    XCTAssert(sUUIDPath.length == 2);
    XCTAssertEqualObjects(sUUIDPath.peripheralUUID, nsUUID);
    XCTAssertEqualObjects(sUUIDPath.serviceUUID, sUUID);
    XCTAssertNil(sUUIDPath.characteristicUUID);

    RZBUUIDPath *cUUIDPath = RZBUUIDP(nsUUID, sUUID, cUUID);
    XCTAssert(cUUIDPath.length == 3);
    XCTAssertEqualObjects(cUUIDPath.peripheralUUID, nsUUID);
    XCTAssertEqualObjects(cUUIDPath.serviceUUID, sUUID);
    XCTAssertEqualObjects(cUUIDPath.characteristicUUID, cUUID);
}

- (void)testEnumerate
{
    NSUUID *nsUUID = [NSUUID UUID];
    CBUUID *sUUID = [CBUUID UUIDWithString:@"01234567"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"12345678"];

    RZBUUIDPath *pUUIDPath = RZBUUIDP(nsUUID);
    RZBUUIDPath *sUUIDPath = RZBUUIDP(nsUUID, sUUID);
    RZBUUIDPath *cUUIDPath = RZBUUIDP(nsUUID, sUUID, cUUID);

    NSArray *UUIDs = @[nsUUID, sUUID, cUUID];

    for (RZBUUIDPath *UUIDPath in @[pUUIDPath, sUUIDPath, cUUIDPath]) {
        __block NSUInteger foundIndex = 0;
        [UUIDPath enumerateUUIDsUsingBlock:^(id NSUUIDorCBUUID, NSUInteger idx) {
            XCTAssert(foundIndex == idx);
            XCTAssertEqualObjects(UUIDs[idx], NSUUIDorCBUUID);
            foundIndex++;
        }];
        XCTAssert(foundIndex == UUIDPath.length);
    }
    XCTAssertThrows([pUUIDPath enumerateUUIDsUsingBlock:nil]);
}

- (void)testDescription
{
    NSUUID *nsUUID = [NSUUID UUID];
    CBUUID *sUUID = [CBUUID UUIDWithString:@"01234567"];
    CBUUID *cUUID = [CBUUID UUIDWithString:@"12345678"];

    RZBUUIDPath *pUUIDPath = RZBUUIDP(nsUUID);
    RZBUUIDPath *sUUIDPath = RZBUUIDP(nsUUID, sUUID);
    RZBUUIDPath *cUUIDPath = RZBUUIDP(nsUUID, sUUID, cUUID);

    XCTAssert([pUUIDPath.description containsString:@"RZBUUIDPath"]);
    XCTAssert([sUUIDPath.description containsString:@"RZBUUIDPath"]);
    XCTAssert([cUUIDPath.description containsString:@"RZBUUIDPath"]);
}


@end
