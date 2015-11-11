//
//  RZBCommandDispatch.h
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@class RZBCommand;
@class RZBUUIDPath;

/**
 * Manage the execution and dependency management of the command objects.
 * This also provides some helpers to build dependent commands.
 */
@interface RZBCommandDispatch : NSObject

- (instancetype)initWithQueue:(dispatch_queue_t)queue context:(id)context;

@property (nonatomic, strong, readonly) NSMutableArray *commands;
@property (nonatomic, strong, readonly) dispatch_queue_t queue;
@property (nonatomic, weak, readonly) id context;
@property (assign) NSUInteger dispatchCounter;

/**
 * Return all commands of the specified class matching the UUIDPath.
 *
 * @param cls the RZBCommand subclass name to filter by. Specify nil to return all commands.
 * @param UUIDPath the UUIDPath to filter by.
 */
- (NSArray *)commandsOfClass:(Class)cls
            matchingUUIDPath:(RZBUUIDPath *)UUIDPath;

/**
 * Return all commands of the specified class matching the UUIDPath.
 *
 * @param cls the RZBCommand subclass name to filter by. Specify nil to return all commands.
 * @param UUIDPath the UUIDPath to filter by.
 * @param isExecuted only return commands that match the isExecuted state.
 */
- (NSArray *)commandsOfClass:(Class)cls
            matchingUUIDPath:(RZBUUIDPath *)UUIDPath
                  isExecuted:(BOOL)isExecuted;

/**
 * Return a command of the specified class matching the UUIDPath.
 *
 * @param cls the RZBCommand subclass name to filter by. Specify nil to return all commands.
 * @param UUIDPath the UUIDPath to filter by.
 * @param createNew create a new class with UUIDPath as a starting state if createNew is YES, and a matching command is not found.
 */
- (id)commandOfClass:(Class)cls
    matchingUUIDPath:(RZBUUIDPath *)UUIDPath
           createNew:(BOOL)createNew;

/**
 * Return a command of the specified class matching the UUIDPath.
 *
 * @param cls the RZBCommand subclass name to filter by. Specify nil to return all commands.
 * @param UUIDPath the UUIDPath to filter by.
 * @param isExecuted filter commands that match the isExecuted state.
 * @param createNew create a new class with UUIDPath as a starting state if createNew is YES, and a matching command is not found.
 */
- (id)commandOfClass:(Class)cls
    matchingUUIDPath:(RZBUUIDPath *)UUIDPath
          isExecuted:(BOOL)isExecuted
           createNew:(BOOL)createNew;


/**
 * Complete the specified command with the object and error. This will
 * also chain any errors along to dependent commands and dispatch any
 * commands that were dependent on this command.
 */
- (void)completeCommand:(RZBCommand *)command
             withObject:(id)object
                  error:(NSError *)error;

/**
 * Reset all commands that are pending. This is used to re-execute things when
 * bluetooth crashes.
 */
- (void)resetCommands;

/**
 * Submit a new command.
 */
- (void)dispatchCommand:(RZBCommand *)command;

/**
 * Attempt to dispatch any un-executed commands
 */
- (void)dispatchPendingCommands;

@end
