//
//  RZBMockEnableMock.h
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@class RZBMockCentralManager, RZBMockPeripheral, RZBMockPeripheralManager;

/**
 * RZBEnableMock swizzles [CBCentralManager alloc] and [CBPeripheralManager alloc] 
 * so consumers of Core Bluetooth can use the mocked objects without injecting them
 * in the consumer side. Once RZBEnableMock(YES) is called, the object returned by
 * [CBCentralManager alloc] will actually be an RZBMockCentralManager, and the object
 * returned by [CBPeripheralManager alloc] will conform to RZBMockPeripheralManager.
 *
 * I know this sounds terrifying but it works great in objective-c. HOWEVER, in Swift,
 * alloc isn't called when initializing an object, so you have to use the the
 * `make()` factory methods which call the alloc in objective-c.
 */
extern void RZBEnableMock(BOOL enableMock);

/**
 * Extension to access the mocked API that is backing this object. If the object is actualy
 * a mock it will return self, otherwise the property will return nil.
 */
@interface CBCentralManager (RZBEnableMock)

+ (instancetype _Nonnull)make;

@property (strong, nonatomic, readonly, nullable) RZBMockCentralManager *mock;

@end

/**
 * Extension to access the mocked API that is backing this object. If the object is actualy
 * a mock it will return self, otherwise the property will return nil.
 */
@interface CBPeripheral (RZBEnableMock)

@property (strong, nonatomic, readonly, nullable) RZBMockPeripheral *mock;

@end

/**
 * Extension to access the mocked API that is backing this object. If the object is actualy
 * a mock it will return self, otherwise the property will return nil.
 */
@interface CBPeripheralManager (RZBEnableMock)

@property (strong, nonatomic, readonly, nullable) RZBMockPeripheralManager *mock;

@end
