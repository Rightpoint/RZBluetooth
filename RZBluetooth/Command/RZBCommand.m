//
//  RZBCommand.m
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCommand.h"
#import "CBCharacteristic+RZBExtension.h"
#import "RZBUUIDPath.h"
#import "RZBErrors.h"
#import "RZBCentralManager+Private.h"

#define RZBoolString(value) (value ? @"YES" : @"NO")

@interface RZBCommand ()

@property (copy, nonatomic) RZBCallbackBlock callbackBlock;

@end

@implementation RZBCommand

+ (NSPredicate *)predicateMatchingUUIDPath:(RZBUUIDPath *)UUIDPath;
{
    return [NSPredicate predicateWithBlock:^BOOL(RZBCommand *command, NSDictionary *bindings) {
        return ([command isKindOfClass:self] && [command matchesUUIDPath:UUIDPath]);
    }];
}

+ (NSPredicate *)predicateMatchingUUIDPath:(RZBUUIDPath *)UUIDPath isExecuted:(BOOL)isExecuted
{
    return [NSPredicate predicateWithBlock:^BOOL(RZBCommand *command, NSDictionary *bindings) {
        return ([command isKindOfClass:self] &&
                [command matchesUUIDPath:UUIDPath] &&
                command.isExecuted == isExecuted);
    }];
}

+ (NSArray *)UUIDPathKeys
{
    return [[RZBUUIDPath UUIDkeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *key, NSDictionary *bindings) {
        return [self instancesRespondToSelector:NSSelectorFromString(key)];
    }]];
}

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    return YES;
}

- (instancetype)initWithUUIDPath:(RZBUUIDPath *)UUIDPath
{
    NSArray *UUIDPathKeys = self.class.UUIDPathKeys;
    NSAssert(UUIDPathKeys.count >= UUIDPath.length, @"%@ does not support UUIDPath: %@", self.class, UUIDPath);
    self = [super init];
    if (self) {
        [UUIDPath enumerateUUIDsUsingBlock:^(id UUID, NSUInteger idx) {
            NSString *UUIDPathKey = UUIDPathKeys[idx];
            [self setValue:UUID forKey:UUIDPathKey];
        }];
    }
    return self;
}

- (BOOL)matchesUUIDPath:(RZBUUIDPath *)UUIDPath
{
    if (UUIDPath == nil) {
        return YES;
    }
    __block BOOL matches = YES;
    NSArray *UUIDPathKeys = self.class.UUIDPathKeys;
    // If the UUIDPath has more UUID's than this class supports, return NO.
    if (UUIDPath.length > UUIDPathKeys.count) {
        return NO;
    }
    [UUIDPath enumerateUUIDsUsingBlock:^(id NSUUIDorCBUUID, NSUInteger idx) {
        NSString *UUIDPathKey = UUIDPathKeys[idx];
        if ([self respondsToSelector:NSSelectorFromString(UUIDPathKey)] &&
            ![[self valueForKey:UUIDPathKey] isEqual:NSUUIDorCBUUID]) {
            matches = NO;
        }
    }];
    return matches;
}

- (void)addCallbackBlock:(RZBCallbackBlock)callbackBlock
{
    NSParameterAssert(callbackBlock);
    if (self.callbackBlock == nil) {
        self.callbackBlock = callbackBlock;
    }
    else {
        RZBCallbackBlock currentBlock = self.callbackBlock;
        self.callbackBlock = ^(id obj, NSError *error) {
            currentBlock(obj, error);
            callbackBlock(obj, error);
        };
    }
}

- (void)completeWithObject:(id)object error:(inout NSError **)error;
{
    if (self.callbackBlock) {
        self.callbackBlock(object, *error);
    }
    self.isCompleted = YES;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p isExecuted=%@, isCompleted=%@", self.class, self, RZBoolString(self.isExecuted), RZBoolString(self.isCompleted)];

    [self.class.UUIDPathKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        [description appendFormat:@" %@=%@", key, [[self valueForKey:key] UUIDString]];
    }];

    if (self.retryAfter) {
        [description appendFormat:@" dependentCommand=<%@:%p>", self.retryAfter.class, self.retryAfter];
    }

    [description appendString:@">"];
    return description;
}

@end

@implementation RZBConnectCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context peripheralForUUID:self.peripheralUUID];
    NSAssert(peripheral.state != CBPeripheralStateConnected, @"Should not execute connect on connected peripheral");

    [context.centralManager connectPeripheral:peripheral options:self.connectOptions];
    return YES;
}

@end

@implementation RZBCancelConnectionCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context peripheralForUUID:self.peripheralUUID];

    if (peripheral.state == CBPeripheralStateConnected ||
        peripheral.state == CBPeripheralStateConnecting) {
        [context.centralManager cancelPeripheralConnection:peripheral];
    }
    else {
        self.isCompleted = YES;
    }
    return YES;
}

@end

@implementation RZBDiscoverServiceCommand

- (instancetype)initWithUUIDPath:(RZBUUIDPath *)UUIDPath
{
    self = [super initWithUUIDPath:UUIDPath];
    _serviceUUIDs = [NSMutableArray array];
    return self;
}

- (void)addServiceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(serviceUUID);
    if ([self.serviceUUIDs containsObject:serviceUUID] == NO) {
        [self.serviceUUIDs addObject:serviceUUID];
    }
}

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                triggeredByCommand:self];
    [peripheral discoverServices:self.serviceUUIDs];
    return peripheral != nil;
}

- (NSArray *)undiscoveredUUIDsInPeripheral:(CBPeripheral *)peripheral
{
    NSMutableArray *undiscoveredUUIDs = [self.serviceUUIDs mutableCopy];
    for (CBService *service in peripheral.services) {
        [undiscoveredUUIDs removeObject:service.UUID];
    }
    return undiscoveredUUIDs;
}

- (void)completeWithObject:(CBPeripheral *)peripheral error:(inout NSError **)error
{
    NSArray *undiscoveredUUIDs = [self undiscoveredUUIDsInPeripheral:peripheral];
    if (*error == nil && undiscoveredUUIDs.count > 0) {
        *error = [NSError errorWithDomain:RZBluetoothErrorDomain
                                     code:RZBluetoothDiscoverServiceError
                                 userInfo:@{RZBluetoothUndiscoveredUUIDsKey: undiscoveredUUIDs}];
    }
    [super completeWithObject:peripheral error:error];
}

@end

@implementation RZBDiscoverCharacteristicCommand

- (instancetype)initWithUUIDPath:(RZBUUIDPath *)UUIDPath
{
    self = [super initWithUUIDPath:UUIDPath];
    _characteristicUUIDs = [NSMutableArray array];
    return self;
}

- (void)addCharacteristicUUID:(CBUUID *)characteristicUUID
{
    NSParameterAssert(characteristicUUID);
    if ([self.characteristicUUIDs containsObject:characteristicUUID] == NO) {
        [self.characteristicUUIDs addObject:characteristicUUID];
    }
}

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                triggeredByCommand:self];
    
    CBService *service = [context serviceForUUID:self.serviceUUID
                                    onPeripheral:peripheral
                              triggeredByCommand:self];
    if (service) {
        [peripheral discoverCharacteristics:self.characteristicUUIDs
                                 forService:service];
    }
    return service != nil;
}

- (NSArray *)undiscoveredUUIDsInService:(CBService *)service
{
    NSMutableArray *undiscoveredUUIDs = [self.characteristicUUIDs mutableCopy];
    for (CBCharacteristic *characteristic in service.characteristics) {
        [undiscoveredUUIDs removeObject:characteristic.UUID];
    }
    return undiscoveredUUIDs;
}

- (void)completeWithObject:(CBService *)service error:(inout NSError **)error
{
    NSArray *undiscoveredUUIDs = [self undiscoveredUUIDsInService:service];
    if (*error == nil && undiscoveredUUIDs.count > 0) {
        *error = [NSError errorWithDomain:RZBluetoothErrorDomain
                                     code:RZBluetoothDiscoverCharacteristicError
                                 userInfo:@{RZBluetoothUndiscoveredUUIDsKey: undiscoveredUUIDs}];
    }
    [super completeWithObject:service error:error];
}

@end

@implementation RZBReadCharacteristicCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                triggeredByCommand:self];

    CBService *service = [context serviceForUUID:self.serviceUUID
                                    onPeripheral:peripheral
                              triggeredByCommand:self];

    CBCharacteristic *characteristic = [context characteristicForUUID:self.characteristicUUID
                                                            onService:service
                                                   triggeredByCommand:self];
    if (characteristic) {
        [peripheral readValueForCharacteristic:characteristic];
    }
    return characteristic != nil;
}

@end

@implementation RZBNotifyCharacteristicCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                triggeredByCommand:self];

    CBService *service = [context serviceForUUID:self.serviceUUID
                                    onPeripheral:peripheral
                              triggeredByCommand:self];

    CBCharacteristic *characteristic = [context characteristicForUUID:self.characteristicUUID
                                                            onService:service
                                                   triggeredByCommand:self];
    if (characteristic) {
        [peripheral setNotifyValue:self.notify forCharacteristic:characteristic];
    }
    return characteristic != nil;
}

@end

@implementation RZBWriteCharacteristicCommand

- (CBCharacteristicWriteType)writeType
{
    return CBCharacteristicWriteWithoutResponse;
}

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                triggeredByCommand:self];

    CBService *service = [context serviceForUUID:self.serviceUUID
                                    onPeripheral:peripheral
                              triggeredByCommand:self];

    CBCharacteristic *characteristic = [context characteristicForUUID:self.characteristicUUID
                                                            onService:service
                                                   triggeredByCommand:self];

    if (characteristic) {
        [peripheral writeValue:self.data forCharacteristic:characteristic type:self.writeType];
        self.isCompleted = (self.writeType == CBCharacteristicWriteWithoutResponse);
        return YES;
    }
    else {
        return NO;
    }
}

@end

@implementation RZBWriteWithReplyCharacteristicCommand

- (CBCharacteristicWriteType)writeType
{
    return CBCharacteristicWriteWithResponse;
}

@end

@implementation RZBScanCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context
{
    [context.centralManager scanForPeripheralsWithServices:self.serviceUUIDs
                                                   options:self.scanOptions];
    return YES;
}

@end