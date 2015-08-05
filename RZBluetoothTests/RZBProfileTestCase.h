//
//  RZBProfileTestCase.h
//  RZBluetooth
//
//  Created by Brian King on 8/4/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RZBTestableCentralManager.h"
#import "RZBCentralManager+Private.h"
#import "RZBMockCentralManager.h"

#define RZBAssertCommandCount(cnt) XCTAssert(self.centralManager.dispatch.commands.count == cnt, @"Expected %zd commands, saw %zd", cnt, self.centralManager.dispatch.commands.count)

@interface RZBProfileTestCase : XCTestCase

@property (strong, nonatomic) RZBTestableCentralManager *centralManager;
@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;

- (void)waitForQueueFlush;

@end
