//
//  RZBCommandTests.m
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RZBCommand.h"
#import "RZBUUIDPath.h"
#import "XCTestCase+Helpers.h"
#import "RZTestCommands.h"

@interface RZBCommandTests : XCTestCase

@end

@implementation RZBCommandTests

- (void)testUUIDPathMatching
{
    RZBPTestCommand *pCommand = [[RZBPTestCommand alloc] initWithUUIDPath:self.class.pUUIDPath];

    XCTAssertTrue([pCommand matchesUUIDPath:self.class.pUUIDPath]);
    XCTAssertFalse([pCommand matchesUUIDPath:self.class.sUUIDPath]);
    XCTAssertFalse([pCommand matchesUUIDPath:self.class.cUUIDPath]);

    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(self.class.p2UUID)]);

    RZBSTestCommand *sCommand = [[RZBSTestCommand alloc] initWithUUIDPath:self.class.sUUIDPath];

    XCTAssertTrue([sCommand matchesUUIDPath:self.class.pUUIDPath]);
    XCTAssertTrue([sCommand matchesUUIDPath:self.class.sUUIDPath]);
    XCTAssertFalse([sCommand matchesUUIDPath:self.class.cUUIDPath]);

    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(self.class.pUUID, self.class.s2UUID)]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(self.class.p2UUID, self.class.sUUID)]);

    RZBCTestCommand *cCommand = [[RZBCTestCommand alloc] initWithUUIDPath:self.class.cUUIDPath];

    XCTAssertTrue([cCommand matchesUUIDPath:self.class.pUUIDPath]);
    XCTAssertTrue([cCommand matchesUUIDPath:self.class.sUUIDPath]);
    XCTAssertTrue([cCommand matchesUUIDPath:self.class.cUUIDPath]);

    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(self.class.p2UUID, self.class.sUUID, self.class.cUUID)]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(self.class.pUUID, self.class.s2UUID, self.class.cUUID)]);
    XCTAssertFalse([pCommand matchesUUIDPath:RZBUUIDP(self.class.pUUID, self.class.sUUID, self.class.c2UUID)]);
}

- (void)testCallback
{
    NSUUID *completionObject = [NSUUID UUID];
    NSError *completionError = [NSError errorWithDomain:NSCocoaErrorDomain code:22 userInfo:nil];
    __block NSUInteger triggerCount = 0;
    RZBPTestCommand *pCommand = [[RZBPTestCommand alloc] initWithUUIDPath:self.class.pUUIDPath];
    XCTAssertThrows([pCommand addCallbackBlock:nil]);

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
