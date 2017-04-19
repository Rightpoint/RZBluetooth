//
//  RZBCommand.m
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCommand.h"
#import "RZBUUIDPath.h"
#import "RZBErrors.h"
#import "RZBCentralManager+CommandHelper.h"
#import "RZBPeripheral+Private.h"
#import "RZBLog+Private.h"

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

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    CBManagerState state = context.coreCentralManager.state;
    BOOL bluetoothReady = (state == CBManagerStatePoweredOn);
    if (error) {
        *error = RZBluetoothErrorForState(state);
    }
    return bluetoothReady;
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

- (BOOL)isUserInteraction
{
    return self.expiresAt > 0;
}

- (BOOL)isExpired
{
    return (self.expiresAt > 0 && self.expiresAt <= [[NSDate date] timeIntervalSinceReferenceDate]);
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
    if (self.callbackBlock == nil && callbackBlock) {
        self.callbackBlock = callbackBlock;
    }
    else if (self.callbackBlock) {
        RZBCallbackBlock currentBlock = self.callbackBlock;
        self.callbackBlock = ^(id obj, NSError *error) {
            currentBlock(obj, error);
            callbackBlock(obj, error);
        };
    }
}

- (BOOL)completeWithObject:(id)object error:(inout NSError **)error;
{
    if (self.callbackBlock) {
        self.callbackBlock(object, *error);
    }
    self.isCompleted = YES;
    return *error == nil;
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

    if (self.expiresAt > 0) {
        [description appendFormat:@" expiresAt=<%f>", self.expiresAt];
    }

    [description appendString:@">"];
    return description;
}

@end

@implementation RZBConnectCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    CBPeripheral *peripheral = [context corePeripheralForUUID:self.peripheralUUID];
    NSAssert(peripheral.state != CBPeripheralStateConnected, @"Should not execute connect on connected peripheral");

    if (isReady) {
        RZBLogCommand(@"connectPeripheral:%@ options:%@", RZBLogIdentifier(peripheral), self.connectOptions);

        [context.coreCentralManager connectPeripheral:peripheral options:self.connectOptions];
    }
    return isReady;
}

@end

@implementation RZBCancelConnectionCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    [super executeCommandWithContext:context error:error];
    CBPeripheral *peripheral = [context corePeripheralForUUID:self.peripheralUUID];

    if (peripheral.state == CBPeripheralStateConnected ||
        peripheral.state == CBPeripheralStateConnecting) {
        RZBLogCommand(@"cancelPeripheralConnection: %@", RZBLogIdentifier(peripheral));
        [context.coreCentralManager cancelPeripheralConnection:peripheral];
    }
    else {
        RZBLogCommand(@"Already Cancelled: %@", RZBLogIdentifier(peripheral));
        self.isCompleted = YES;
    }
    return YES;
}

@end

@implementation RZBReadRSSICommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                    triggeredByCommand:self];
        if (peripheral) {
            RZBLogCommand(@"readRSSI: %@", RZBLogIdentifier(peripheral));

            [peripheral readRSSI];
        }
        isReady = (peripheral != nil);
    }
    return isReady;
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

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                    triggeredByCommand:self];
        if (peripheral) {
            RZBLogCommand(@"%@ discoverServices:%@", RZBLogIdentifier(peripheral), RZBLogArray(self.serviceUUIDs));

            [peripheral discoverServices:self.serviceUUIDs];
        }
        isReady = (peripheral != nil);
    }
    return isReady;
}

- (NSArray *)undiscoveredUUIDsInPeripheral:(CBPeripheral *)peripheral
{
    NSMutableArray *undiscoveredUUIDs = [self.serviceUUIDs mutableCopy];
    for (CBService *service in peripheral.services) {
        [undiscoveredUUIDs removeObject:service.UUID];
    }
    return undiscoveredUUIDs;
}

- (BOOL)completeWithObject:(RZBPeripheral *)peripheral error:(inout NSError **)error
{
    NSArray *undiscoveredUUIDs = [self undiscoveredUUIDsInPeripheral:peripheral.corePeripheral];
    if (*error == nil && undiscoveredUUIDs.count > 0) {
        *error = [NSError errorWithDomain:RZBluetoothErrorDomain
                                     code:RZBluetoothDiscoverServiceError
                                 userInfo:@{RZBluetoothUndiscoveredUUIDsKey: undiscoveredUUIDs}];
    }
    return [super completeWithObject:peripheral error:error];
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

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                    triggeredByCommand:self];

        CBService *service = [context serviceForUUID:self.serviceUUID
                                        onPeripheral:peripheral
                                  triggeredByCommand:self];
        if (service) {
            RZBLogCommand(@"%@ discoverCharacteristics:%@ forService:%@", RZBLogIdentifier(peripheral), RZBLogArray(self.characteristicUUIDs), RZBLogUUID(service));

            [peripheral discoverCharacteristics:self.characteristicUUIDs
                                     forService:service];
        }
        isReady = (service != nil);
    }
    return isReady;
}

- (NSArray *)undiscoveredUUIDsInService:(CBService *)service
{
    NSMutableArray *undiscoveredUUIDs = [self.characteristicUUIDs mutableCopy];
    for (CBCharacteristic *characteristic in service.characteristics) {
        [undiscoveredUUIDs removeObject:characteristic.UUID];
    }
    return undiscoveredUUIDs;
}

- (BOOL)completeWithObject:(CBService *)service error:(inout NSError **)error
{
    NSArray *undiscoveredUUIDs = [self undiscoveredUUIDsInService:service];
    if (*error == nil && undiscoveredUUIDs.count > 0) {
        *error = [NSError errorWithDomain:RZBluetoothErrorDomain
                                     code:RZBluetoothDiscoverCharacteristicError
                                 userInfo:@{RZBluetoothUndiscoveredUUIDsKey: undiscoveredUUIDs}];
    }
    return [super completeWithObject:service error:error];
}

@end

@implementation RZBReadCharacteristicCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                    triggeredByCommand:self];

        CBService *service = [context serviceForUUID:self.serviceUUID
                                        onPeripheral:peripheral
                                  triggeredByCommand:self];

        CBCharacteristic *characteristic = [context characteristicForUUID:self.characteristicUUID
                                                                onService:service
                                                       triggeredByCommand:self];
        if (characteristic) {
            RZBLogCommand(@"%@ readValueForCharacteristic:%@", RZBLogIdentifier(peripheral), self.characteristicUUID);

            [peripheral readValueForCharacteristic:characteristic];
        }
        isReady = (characteristic != nil);
    }
    return isReady;
}

@end

@implementation RZBNotifyCharacteristicCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                    triggeredByCommand:self];

        CBService *service = [context serviceForUUID:self.serviceUUID
                                        onPeripheral:peripheral
                                  triggeredByCommand:self];

        CBCharacteristic *characteristic = [context characteristicForUUID:self.characteristicUUID
                                                                onService:service
                                                       triggeredByCommand:self];
        if (characteristic) {
            RZBLogCommand(@"%@ setNotifyValue:%@ forCharacteristic:%@", RZBLogIdentifier(peripheral), RZBLogBool(self.notify), self.characteristicUUID);

            [peripheral setNotifyValue:self.notify forCharacteristic:characteristic];
        }
        isReady = (characteristic != nil);
    }
    return isReady;
}

@end

@implementation RZBWriteCharacteristicCommand

- (CBCharacteristicWriteType)writeType
{
    return CBCharacteristicWriteWithoutResponse;
}

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        CBPeripheral *peripheral = [context connectedPeripheralForUUID:self.peripheralUUID
                                                    triggeredByCommand:self];

        CBService *service = [context serviceForUUID:self.serviceUUID
                                        onPeripheral:peripheral
                                  triggeredByCommand:self];

        CBCharacteristic *characteristic = [context characteristicForUUID:self.characteristicUUID
                                                                onService:service
                                                       triggeredByCommand:self];

        if (characteristic) {
            RZBLogCommand(@"%@ writeData:<data> forCharacteristic:%@ type:%@", RZBLogIdentifier(peripheral), self.characteristicUUID, @(self.writeType));
            RZBLog(RZBLogLevelWriteCommandData, @"Data=%@", self.data);

            [peripheral writeValue:self.data forCharacteristic:characteristic type:self.writeType];
            self.isCompleted = (self.writeType == CBCharacteristicWriteWithoutResponse);
        }
        isReady = (characteristic != nil);
    }
    return isReady;
}

@end

@implementation RZBWriteWithReplyCharacteristicCommand

- (CBCharacteristicWriteType)writeType
{
    return CBCharacteristicWriteWithResponse;
}

@end

@implementation RZBScanCommand

- (BOOL)executeCommandWithContext:(RZBCentralManager *)context error:(inout NSError **)error
{
    BOOL isReady = [super executeCommandWithContext:context error:error];
    if (isReady) {
        RZBLogCommand(@"scanForPeripheralsWithServices:%@ options:%@", RZBLogArray(self.serviceUUIDs), self.scanOptions);

        [context.coreCentralManager scanForPeripheralsWithServices:self.serviceUUIDs
                                                           options:self.scanOptions];
    }
    return isReady;
}

@end
