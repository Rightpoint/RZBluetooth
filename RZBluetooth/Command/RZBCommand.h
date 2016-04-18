//
//  RZBCommand.h
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

@class RZBCommandDispatch;
@class RZBUUIDPath;

typedef void(^RZBCallbackBlock)(id object, NSError *error);

/**
 * RZBCommand is a class hierarchy representing an asynchronous command that completes.
 * A command encapsulates one bluetooth action. A command is executed with a
 * context, and a command can use the context to probe the environment and create
 * other commands to resolve state. Returning NO from `executeCommandWithContext:` indicates
 * that the command can not complete.
 *
 * Commands are completed via `completeWithObject:error:`. This is triggered by
 * the bluetooth delegate API's.
 */
@interface RZBCommand : NSObject

+ (NSPredicate *)predicateMatchingUUIDPath:(RZBUUIDPath *)UUIDPath;
+ (NSPredicate *)predicateMatchingUUIDPath:(RZBUUIDPath *)UUIDPath isExecuted:(BOOL)isExecuted;

- (instancetype)initWithUUIDPath:(RZBUUIDPath *)UUIDPath;

@property (strong, nonatomic) RZBCommand *retryAfter;
@property (assign, nonatomic) BOOL isExecuted;
@property (assign, nonatomic) BOOL isCompleted;
@property (assign, nonatomic) NSTimeInterval expiresAt;
@property (assign, nonatomic, readonly) BOOL isUserInteraction;
@property (assign, nonatomic, readonly) BOOL isExpired;

- (BOOL)executeCommandWithContext:(id)context error:(inout NSError **)error;

- (BOOL)matchesUUIDPath:(RZBUUIDPath *)UUIDPath;

- (void)addCallbackBlock:(RZBCallbackBlock)callbackBlock;

- (BOOL)completeWithObject:(id)object error:(inout NSError **)error;

@end

@interface RZBConnectCommand : RZBCommand

@property (copy, nonatomic) NSDictionary *connectOptions;
@property (copy, nonatomic) NSUUID *peripheralUUID;

@end

@interface RZBCancelConnectionCommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;

@end

@interface RZBReadRSSICommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;

@end

@interface RZBDiscoverServiceCommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;
@property (strong, nonatomic) NSMutableArray *serviceUUIDs;

- (void)addServiceUUID:(CBUUID *)serviceUUID;

@end

@interface RZBDiscoverCharacteristicCommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;
@property (copy, nonatomic) CBUUID *serviceUUID;
@property (strong, nonatomic) NSMutableArray *characteristicUUIDs;

- (void)addCharacteristicUUID:(CBUUID *)characteristicUUID;

@end

@interface RZBReadCharacteristicCommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;
@property (copy, nonatomic) CBUUID *serviceUUID;
@property (copy, nonatomic) CBUUID *characteristicUUID;

@end

@interface RZBNotifyCharacteristicCommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;
@property (copy, nonatomic) CBUUID *serviceUUID;
@property (copy, nonatomic) CBUUID *characteristicUUID;
@property (assign, nonatomic) BOOL notify;

@end

@interface RZBWriteCharacteristicCommand : RZBCommand

@property (copy, nonatomic) NSUUID *peripheralUUID;
@property (copy, nonatomic) CBUUID *serviceUUID;
@property (copy, nonatomic) CBUUID *characteristicUUID;
@property (copy, nonatomic) NSData *data;

@end

@interface RZBWriteWithReplyCharacteristicCommand : RZBWriteCharacteristicCommand

@end

@interface RZBScanCommand : RZBCommand

@property (copy, nonatomic) NSArray *serviceUUIDs;
@property (copy, nonatomic) NSDictionary *scanOptions;

@end
