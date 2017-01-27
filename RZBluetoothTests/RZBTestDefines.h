//
//  RZBTestDefines.h
//  RZBluetooth
//
//  Created by Brian King on 10/10/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#define RZBAssertCommandCount(cnt) XCTAssert(self.centralManager.dispatch.commands.count == cnt, @"Expected %zd commands, saw %zd", cnt, self.centralManager.dispatch.commands.count)
#define RZBAssertHasCommand(cmdClass, UUIDPath, isExec) RZBAssertHasCommands(cmdClass, UUIDPath, isExec, 1)

#define RZBAssertHasCommands(cmdClass, UUIDPath, isExec, c) ({\
NSArray *cmds = [self.centralManager.dispatch commandsOfClass:[cmdClass class] matchingUUIDPath:UUIDPath isExecuted:isExec];\
XCTAssert(cmds.count == c, @"Did not find an %@ command of class %@\n%@\n", isExec ? @"executed" : @"un-executed", [cmdClass class], self.centralManager.dispatch.commands);\
});

#define RZBAssertCommandCount(cnt) XCTAssert(self.centralManager.dispatch.commands.count == cnt, @"Expected %zd commands, saw %zd", cnt, self.centralManager.dispatch.commands.count)

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 || __TV_OS_VERSION_MAX_ALLOWED >= 100000
#else
#define CBManagerState CBCentralManagerState
#define CBManagerStateUnknown CBCentralManagerStateUnknown
#define CBManagerStateResetting CBCentralManagerStateResetting
#define CBManagerStateUnsupported CBCentralManagerStateUnsupported
#define CBManagerStateUnauthorized CBCentralManagerStateUnauthorized
#define CBManagerStatePoweredOff CBCentralManagerStatePoweredOff
#define CBManagerStatePoweredOn CBCentralManagerStatePoweredOn
#endif

