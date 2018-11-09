//
//  RZBMockEnableMock.m
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBEnableMock.h"

@import CoreBluetooth;
@import ObjectiveC.runtime;
#import "RZBMockCentralManager.h"
#import "RZBMockPeripheral.h"
#import "RZBMockPeripheralManager.h"

/*
 * The following two functions are IMPs used to over-ride alloc for 
 * CBCentralManager and CBPeripheralManager. I don't have a clear reason
 * why the CFBridgingRetain is needed. The best theory I have is that ARC
 * has some magic around alloc that the swizzling breaks. Either way,
 * the objects created by these methods have the retain count set correctly
 * and do properly dealloc.
 */

id RZBMockCentralManagerAlloc(id self, SEL cmd) {
    id obj = [RZBMockCentralManager alloc];
    CFBridgingRetain(obj);
    return obj;
}

id RZBMockPeripheralManagerAlloc(id self, SEL cmd) {
    id obj = [RZBMockPeripheralManager alloc];
    CFBridgingRetain(obj);
    return obj;
}

void RZBEnableMock(BOOL enableMock)
{
    Method defaultAlloc = class_getClassMethod([NSObject class], @selector(alloc));

    if (enableMock) {
        Class CentralManager = object_getClass([CBCentralManager class]);
        Class PeripheralManager = object_getClass([CBPeripheralManager class]);
        const char *typeEncoding = method_getTypeEncoding(defaultAlloc);
        class_addMethod(CentralManager, @selector(alloc), (IMP)RZBMockCentralManagerAlloc, typeEncoding);
        class_addMethod(PeripheralManager, @selector(alloc), (IMP)RZBMockPeripheralManagerAlloc, typeEncoding);
    }
    else {
        Method centralManagerAlloc = class_getClassMethod([CBCentralManager class], @selector(alloc));
        Method peripheralManagerAlloc = class_getClassMethod([CBPeripheralManager class], @selector(alloc));
        method_setImplementation(centralManagerAlloc, method_getImplementation(defaultAlloc));
        method_setImplementation(peripheralManagerAlloc, method_getImplementation(defaultAlloc));
    }
}

@implementation CBCentralManager (RZBEnableMock)

+ (instancetype _Nonnull)make
{
    return [[CBCentralManager alloc] init];
}

- (RZBMockCentralManager *)mock
{
    return nil;
}

@end

@implementation CBPeripheral (RZBEnableMock)

- (RZBMockPeripheral *)mock
{
    return nil;
}

@end

@implementation CBPeripheralManager (RZBEnableMock)

+ (instancetype _Nonnull)make
{
    return [[CBPeripheralManager alloc] init];
}

- (RZBMockPeripheralManager *)mock
{
    return nil;
}

@end

@implementation RZBMockCentralManager (RZBEnableMock)

- (RZBMockCentralManager *)mock
{
    return self;
}

@end

@implementation RZBMockPeripheral (RZBEnableMock)

- (RZBMockPeripheral *)mock
{
    return self;
}

@end

@implementation RZBMockPeripheralManager (RZBEnableMock)

- (RZBMockPeripheralManager *)mock
{
    return self;
}

@end
