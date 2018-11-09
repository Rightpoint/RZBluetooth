//
//  RZBCommandContextTests.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import XCTest;

#import "RZBCommandDispatch.h"
#import "RZTestCommands.h"
#import "XCTestCase+Helpers.h"
#import "NSRunLoop+RZBWaitFor.h"
#import "CBUUID+TestUUIDs.h"

@interface RZBCommandDispatchTests : XCTestCase

@property (strong, nonatomic) RZBCommandDispatch *dispatch;

@end

@implementation RZBCommandDispatchTests

- (void)testCommandLookup
{
    self.dispatch = [[RZBCommandDispatch alloc] initWithQueue:nil context:self];
    RZBCTestCommand *cCmd = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    [self.dispatch dispatchCommand:cCmd];
    NSArray *c = nil;
    // Ensure all UUIDPaths work
    c = [self.dispatch commandsOfClass:[RZBCTestCommand class] matchingUUIDPath:RZBUUIDPath.cUUIDPath isExecuted:NO];
    XCTAssertTrue(c.count == 1);
    c = [self.dispatch commandsOfClass:[RZBCTestCommand class] matchingUUIDPath:RZBUUIDPath.sUUIDPath isExecuted:NO];
    XCTAssertTrue(c.count == 1);
    c = [self.dispatch commandsOfClass:[RZBCTestCommand class] matchingUUIDPath:RZBUUIDPath.pUUIDPath isExecuted:NO];
    XCTAssertTrue(c.count == 1);
    c = [self.dispatch commandsOfClass:nil matchingUUIDPath:RZBUUIDPath.pUUIDPath isExecuted:NO];
    XCTAssertTrue(c.count == 1);

    [self waitForQueueFlush];
    // Check isExecuted
    c = [self.dispatch commandsOfClass:[RZBCTestCommand class] matchingUUIDPath:RZBUUIDPath.cUUIDPath isExecuted:NO];
    XCTAssertTrue(c.count == 0);
    c = [self.dispatch commandsOfClass:[RZBCTestCommand class] matchingUUIDPath:RZBUUIDPath.cUUIDPath isExecuted:YES];
    XCTAssertTrue(c.count == 1);

    // Check nil class
    c = [self.dispatch commandsOfClass:nil matchingUUIDPath:RZBUUIDPath.cUUIDPath isExecuted:YES];
    XCTAssertTrue(c.count == 1);

    // Check non-matching class
    c = [self.dispatch commandsOfClass:[RZBSTestCommand class] matchingUUIDPath:RZBUUIDPath.cUUIDPath isExecuted:YES];
    XCTAssertTrue(c.count == 0);
}

- (void)testCommandDispatchExecutionCancelation
{
    self.dispatch = [[RZBCommandDispatch alloc] initWithQueue:nil context:self];
    RZBCTestCommand *cCmd = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    cCmd.shouldExecute = NO;
    [self.dispatch dispatchCommand:cCmd];
    [self waitForQueueFlush];
    XCTAssertTrue(self.dispatch.commands.count == 1);
    XCTAssertTrue(cCmd.isExecuted == NO);

    cCmd.shouldExecute = YES;
    [self.dispatch dispatchPendingCommands];
    [self waitForQueueFlush];
    XCTAssertTrue(self.dispatch.commands.count == 1);
    XCTAssertTrue(cCmd.isExecuted == YES);
}

- (void)testDependentCommands
{
    self.dispatch = [[RZBCommandDispatch alloc] initWithQueue:nil context:self];
    RZBCTestCommand *cmd1 = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    RZBCTestCommand *cmd2 = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    RZBCTestCommand *cmd3 = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    cmd3.retryAfter = cmd2;
    cmd2.retryAfter = cmd1;

    [self.dispatch dispatchCommand:cmd1];
    [self.dispatch dispatchCommand:cmd2];
    [self.dispatch dispatchCommand:cmd3];

    [self waitForQueueFlush];
    XCTAssertTrue(cmd1.isExecuted && cmd2.isExecuted == NO && cmd3.isExecuted == NO);
    XCTAssertTrue(cmd1.isCompleted == NO && cmd2.isCompleted == NO && cmd3.isCompleted == NO);

    [self.dispatch completeCommand:cmd1 withObject:[NSNull null] error:nil];
    [self waitForQueueFlush];
    XCTAssertTrue(cmd1.isExecuted && cmd2.isExecuted && cmd3.isExecuted == NO);
    XCTAssertTrue(cmd1.isCompleted && cmd2.isCompleted == NO && cmd3.isCompleted == NO);

    [self.dispatch completeCommand:cmd2 withObject:[NSNull null] error:nil];
    [self waitForQueueFlush];
    XCTAssertTrue(cmd1.isExecuted && cmd2.isExecuted && cmd3.isExecuted);
    XCTAssertTrue(cmd1.isCompleted && cmd2.isCompleted && cmd3.isCompleted == NO);

    [self.dispatch completeCommand:cmd3 withObject:[NSNull null] error:nil];
    [self waitForQueueFlush];
    XCTAssertTrue(cmd1.isCompleted && cmd2.isCompleted && cmd3.isCompleted);
}

- (void)testDependentCommandErrors
{
    NSMutableArray *errors = [NSMutableArray array];
    self.dispatch = [[RZBCommandDispatch alloc] initWithQueue:nil context:self];
    RZBCTestCommand *cmd1 = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    RZBCTestCommand *cmd2 = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    RZBCTestCommand *cmd3 = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
    cmd3.retryAfter = cmd2;
    cmd2.retryAfter = cmd1;

    for (RZBCommand *cmd in @[cmd1, cmd2, cmd3]) {
        [cmd addCallbackBlock:^(id object, NSError *error) {
            if (error) {
                [errors addObject:error];
            }
        }];
    }

    [self.dispatch dispatchCommand:cmd1];
    [self.dispatch dispatchCommand:cmd2];
    [self.dispatch dispatchCommand:cmd3];

    [self waitForQueueFlush];
    [self.dispatch completeCommand:cmd1 withObject:nil error:(id)[NSNull null]];
    XCTAssertTrue(errors.count == 3);
}

/**
 * This test will do lots of things on lots of threads to try to aggrevate any threading issues.
 */
#define ABUSE_COUNT 100
- (void)testThreadSafety
{
    dispatch_queue_t q = dispatch_queue_create("com.rzbluetooth.test", DISPATCH_QUEUE_SERIAL);
    self.dispatch = [[RZBCommandDispatch alloc] initWithQueue:q context:self];
    dispatch_queue_t b = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(ABUSE_COUNT, b, ^(size_t i) {
        RZBCTestCommand *cmd = [[RZBCTestCommand alloc] initWithUUIDPath:RZBUUIDPath.cUUIDPath];
        [self.dispatch dispatchCommand:cmd];
        dispatch_async(b, ^{
            [self.dispatch completeCommand:cmd
                                withObject:nil
                                     error:(id)[NSNull null]];

        });
        if (i % 10 == 0) {
            dispatch_async(b, ^{
                [self.dispatch resetCommands];
            });
        }
    });

    BOOL done = [[NSRunLoop currentRunLoop] rzb_waitWithTimeout:1.0 forCheck:^BOOL{
        return self.dispatch.commands.count == 0;
    }];
    XCTAssert(done);
}

@end
