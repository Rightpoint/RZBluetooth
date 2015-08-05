//
//  RZBMockCentralTestCase.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RZBluetooth.h"
#import "RZMockBluetooth.h"

#import "RZBCommand.h"
#import "XCTestCase+Helpers.h"
#import "RZBCentralManager+Private.h"
#import "RZBInvocationLog.h"

#define RZBAssertHasCommand(cmdClass, UUIDPath, isExec) RZBAssertHasCommands(cmdClass, UUIDPath, isExec, 1)

#define RZBAssertHasCommands(cmdClass, UUIDPath, isExec, c) ({\
NSArray *cmds = [self.centralManager.dispatch commandsOfClass:[cmdClass class] matchingUUIDPath:UUIDPath isExecuted:isExec];\
XCTAssert(cmds.count == c, @"Did not find an %@ command of class %@\n%@\n", isExec ? @"executed" : @"un-executed", [cmdClass class], self.centralManager.dispatch.commands);\
});

#define RZBAssertCommandCount(cnt) XCTAssert(self.centralManager.dispatch.commands.count == cnt, @"Expected %zd commands, saw %zd", cnt, self.centralManager.dispatch.commands.count)

@interface RZBMockCentralTestCase : XCTestCase <RZBMockCentralManagerDelegate, RZBMockPeripheralDelegate>

@property (strong, nonatomic) RZBTestableCentralManager *centralManager;
@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;
@property (strong, nonatomic) RZBInvocationLog *invocationLog;

- (void)ensureAndCompleteConnectionTo:(NSUUID *)peripheralUUID;
- (void)ensureAndCompleteDiscoveryOfService:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID;
- (void)ensureAndCompleteDiscoveryOfCharacteristic:(CBUUID *)characteristicUUID serviceUUID:(CBUUID *)serviceUUID peripheralUUID:(NSUUID *)peripheralUUID;
- (void)setupConnectedPeripheral;
- (void)triggerThreeCommandsAndStoreErrorsIn:(NSMutableArray *)errors;

@end
