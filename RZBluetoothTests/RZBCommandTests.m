//
//  RZBCommandTests.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import XCTest;

#import "RZBCommand.h"
#import "RZBUUIDPath.h"
#import "XCTestCase+Helpers.h"
#import "RZTestCommands.h"
#import "CBUUID+TestUUIDs.h"

@interface RZBCommandTests : XCTestCase

@end

@implementation RZBCommandTests

- (void)testUUIDPathMatching
{
    RZBPTestCommand *pCommand = [[RZBPTestCommand alloc] initWithUUIDPath:RZBUUIDPath.pUUIDPath];

    XCTAssertTrue([pCommand matchesUUIDPath:RZBUUIDPath.pUUIDPath]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDPath.sUUIDPath]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDPath.cUUIDPath]);

    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(NSUUID.p2UUID)]);

    RZBSTestCommand *sCommand = [[RZBSTestCommand alloc] initWithUUIDPath:RZBUUIDPath.sUUIDPath];

    XCTAssertTrue([sCommand matchesUUIDPath:RZBUUIDPath.pUUIDPath]);
    XCTAssertTrue([sCommand matchesUUIDPath:RZBUUIDPath.sUUIDPath]);
    XCTAssertFalse([sCommand matchesUUIDPath:RZBUUIDPath.cUUIDPath]);

    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(NSUUID.pUUID, CBUUID.s2UUID)]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(NSUUID.p2UUID, CBUUID.sUUID)]);

    RZBCTestCommand *cCommand = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];

    XCTAssertTrue([cCommand matchesUUIDPath:RZBUUIDPath.pUUIDPath]);
    XCTAssertTrue([cCommand matchesUUIDPath:RZBUUIDPath.sUUIDPath]);
    XCTAssertTrue([cCommand matchesUUIDPath:RZBUUIDPath.cUUIDPath]);

    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(NSUUID.p2UUID, CBUUID.sUUID, CBUUID.cUUID)]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(NSUUID.pUUID, CBUUID.s2UUID, CBUUID.cUUID)]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(NSUUID.pUUID, CBUUID.sUUID, CBUUID.c2UUID)]);
}

- (void)testDescription
{
    RZBCTestCommand *cmd = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    XCTAssertTrue([cmd.description containsString:@"isExecuted=NO, isCompleted=NO peripheralUUID="]);
    XCTAssertTrue([cmd.description containsString:@"serviceUUID=0123 characteristicUUID=1234"]);
    XCTAssertTrue([cmd.description containsString:[cmd.class description]]);
    XCTAssertFalse([cmd.description containsString:@"dependentCommand"]);
    cmd.retryAfter = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.sUUIDPath];
    XCTAssertTrue([cmd.description containsString:@"dependentCommand=<RZBCTestCommand:"]);
}

- (void)testCallback
{
    NSUUID *completionObject = [NSUUID UUID];
    NSError *completionError = [NSError errorWithDomain:NSCocoaErrorDomain code:22 userInfo:nil];
    __block NSUInteger triggerCount = 0;
    RZBPTestCommand *pCommand = [[RZBPTestCommand alloc] initWithUUIDPath:RZBUUIDPath.pUUIDPath];
    XCTAssertNoThrow([pCommand addCallbackBlock:nil]);

    [pCommand addCallbackBlock:^(id object, NSError *error) {
        XCTAssertTrue(object == completionObject);
        XCTAssertTrue(error == completionError);
        triggerCount++;
    }];

    [pCommand completeWithObject:completionObject error:&completionError];
    XCTAssertTrue(triggerCount == 1);
    XCTAssertTrue(pCommand.isCompleted);

    pCommand.isCompleted = NO;

    // Add another callback block and ensure they both
    [pCommand addCallbackBlock:^(id object, NSError *error) {
        triggerCount++;
    }];
    [pCommand completeWithObject:completionObject error:&completionError];
    
    XCTAssertTrue(triggerCount == 3);
}

@end
