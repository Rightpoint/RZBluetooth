//
//  RZTestCommands.m
//  RZBluetooth
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTestCommands.h"

@implementation RZBPTestCommand

- (instancetype)initWithUUIDPath:(RZBUUIDPath *)UUIDPath
{
    self = [super initWithUUIDPath:UUIDPath];
    if (self) {
        self.shouldExecute = YES;
    }
    return self;
}

- (BOOL)executeCommandWithContext:(id)context error:(inout NSError **)error
{
    return self.shouldExecute;
}

@end

@implementation RZBSTestCommand

@end

@implementation RZBCTestCommand

@end
