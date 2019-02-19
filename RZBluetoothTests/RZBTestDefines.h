//
//  RZBTestDefines.h
//  RZBluetooth
//
//  Created by Brian King on 10/10/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBluetooth/RZBDefines.h"

#define RZBAssertCommandCount(cnt) XCTAssert(self.centralManager.dispatch.commands.count == cnt, @"Expected %tu commands, saw %tu", cnt, self.centralManager.dispatch.commands.count)
#define RZBAssertHasCommand(cmdClass, UUIDPath, isExec) RZBAssertHasCommands(cmdClass, UUIDPath, isExec, 1)

#define RZBAssertHasCommands(cmdClass, UUIDPath, isExec, c) ({\
NSArray *cmds = [self.centralManager.dispatch commandsOfClass:[cmdClass class] matchingUUIDPath:UUIDPath isExecuted:isExec];\
XCTAssert(cmds.count == c, @"Did not find an %@ command of class %@\n%@\n", isExec ? @"executed" : @"un-executed", [cmdClass class], self.centralManager.dispatch.commands);\
});
