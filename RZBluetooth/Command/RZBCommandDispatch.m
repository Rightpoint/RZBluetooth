//
//  RZBCommandDispatch.m
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCommandDispatch.h"
#import "RZBCommand.h"
#import "RZBUUIDPath.h"
#import "RZBUserInteraction.h"
#import "RZBErrors.h"

@implementation RZBCommandDispatch

- (instancetype)initWithQueue:(dispatch_queue_t)queue context:(id)context
{
    self = [super init];
    if (self) {
        _queue = queue ? queue : dispatch_get_main_queue();
        _commands = [NSMutableArray array];
        _context = context;
    }
    return self;
}

- (NSArray *)synchronizedCommandsCopy
{
    @synchronized(self.commands) {
        return [self.commands copy];
    }
}

- (NSArray *)synchronizedCommandsMatching:(NSPredicate *)predicate
{
    return [self.synchronizedCommandsCopy filteredArrayUsingPredicate:predicate];
}

- (void)dispatchCommand:(RZBCommand *)command
{
    NSParameterAssert(command);
    @synchronized(self.commands) {
        if (![self.commands containsObject:command]) {
            [self.commands addObject:command];
        }
    }
    if ([RZBUserInteraction enabled]) {
        command.expiresAt = [[NSDate date] timeIntervalSinceReferenceDate] + [RZBUserInteraction timeout];
        int64_t timeout = ([RZBUserInteraction timeout] * NSEC_PER_SEC);
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), self.queue, ^{
            [weakSelf checkForExpiredCommands];
        });
    }

    self.dispatchCounter += 1;
    dispatch_async(self.queue, ^{
        [self executeCommand:command];
        self.dispatchCounter -= 1;
    });
}

- (void)dispatchPendingCommands
{
    self.dispatchCounter += 1;
    NSArray *commands = self.synchronizedCommandsCopy;
    dispatch_async(self.queue, ^{
        for (RZBCommand *nextCommand in commands) {
            [self executeCommand:nextCommand];
        }
        self.dispatchCounter -= 1;
    });
}

- (void)resetCommands
{
    for (RZBCommand *nextCommand in self.synchronizedCommandsCopy) {
        nextCommand.isExecuted = NO;
    }
    [self dispatchPendingCommands];
}

- (NSArray *)commandsOfClass:(Class)cls
            matchingUUIDPath:(RZBUUIDPath *)UUIDPath
{
    cls = cls ?: [RZBCommand class];
    return [self synchronizedCommandsMatching:[cls predicateMatchingUUIDPath:UUIDPath]];
}

- (NSArray *)commandsOfClass:(Class)cls
            matchingUUIDPath:(RZBUUIDPath *)UUIDPath
                  isExecuted:(BOOL)isExecuted;
{
    cls = cls ?: [RZBCommand class];
    return [self synchronizedCommandsMatching:[cls predicateMatchingUUIDPath:UUIDPath
                                                                  isExecuted:isExecuted]];
}

- (id)commandOfClass:(Class)cls
    matchingUUIDPath:(RZBUUIDPath *)UUIDPath
           createNew:(BOOL)createNew;
{
    NSArray *commands = [self commandsOfClass:cls matchingUUIDPath:UUIDPath];
    RZBCommand *cmd = [commands firstObject];
    if (cmd == nil && createNew) {
        cmd = [[cls alloc] initWithUUIDPath:UUIDPath];
    }
    return cmd;
}

- (id)commandOfClass:(Class)cls
    matchingUUIDPath:(RZBUUIDPath *)UUIDPath
          isExecuted:(BOOL)isExecuted
           createNew:(BOOL)createNew
{
    NSArray *commands = [self commandsOfClass:cls matchingUUIDPath:UUIDPath isExecuted:isExecuted];
    RZBCommand *cmd = [commands firstObject];
    if (cmd == nil && createNew) {
        cmd = [[cls alloc] initWithUUIDPath:UUIDPath];
    }
    return cmd;
}

- (void)executeCommand:(RZBCommand *)command
{
    NSParameterAssert(command);
    if (command.isExecuted || command.isCompleted || command.retryAfter != nil) {
        return;
    }
    NSError *error = nil;
    command.isExecuted = [command executeCommandWithContext:self.context error:&error];
    if (error) {
        command.isCompleted = YES;
    }
    if (!command.isExecuted) {
        // The command created a dependent command, make sure it is dispatched
        if (command.retryAfter) {
            [self dispatchCommand:command.retryAfter];
        }
    }
    // Prune out the commands that execute and complete. (write w/o reply, disconnect while disconnected)
    if (command.isCompleted) {
        [self completeCommand:command withObject:nil error:error];
    }
}

- (void)completeCommand:(RZBCommand *)command
             withObject:(id)object
                  error:(NSError *)error
{
    NSParameterAssert(command);
    [command completeWithObject:object error:&error];
    NSPredicate *dependentPredicate = [NSPredicate predicateWithBlock:^BOOL(RZBCommand *otherCommand, NSDictionary *bindings) {
        return otherCommand.retryAfter == command;
    }];
    NSArray *dependentCommands = [self synchronizedCommandsMatching:dependentPredicate];
    for (RZBCommand *nextCommand in dependentCommands) {
        nextCommand.retryAfter = nil;
        if (error) {
            [self completeCommand:nextCommand
                       withObject:nil
                            error:error];
        }
        else {
            [self dispatchCommand:nextCommand];
        }
    }
    @synchronized(self.commands) {
        [self.commands removeObject:command];
    }
}

- (void)checkForExpiredCommands
{
    for (__strong RZBCommand *command in [self synchronizedCommandsCopy]) {
        if (command.isExpired) {
            // Obtain the base command to expire
            while (command.retryAfter) {
                command = command.retryAfter;
            }
            // Complete the command with the error
            NSError *expirationError = [NSError errorWithDomain:RZBluetoothErrorDomain
                                                           code:RZBluetoothTimeoutError
                                                       userInfo:nil];

            [self completeCommand:command withObject:nil error:expirationError];
        }
    }
}

@end


