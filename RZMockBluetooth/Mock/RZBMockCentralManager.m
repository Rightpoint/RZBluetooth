//
//  RZBMockCentralManager.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBMockCentralManager.h"
#import "RZBMockPeripheral.h"

@implementation RZBMockCentralManager

@synthesize state = _state;

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.queue = queue ? queue : dispatch_get_main_queue();
        self.options = options;
        self.peripheralsByUUID = [NSMutableDictionary dictionary];
        self.state = CBManagerStateUnknown;
        _isScanning = false;
    }
    return self;
}

- (RZBMockPeripheral *)peripheralForUUID:(NSUUID *)uuid
{
    RZBMockPeripheral *peripheral = self.peripheralsByUUID[uuid];
    if (peripheral == nil) {
        peripheral = [[RZBMockPeripheral alloc] init];
        peripheral.mockCentralManager = self;
        peripheral.identifier = uuid;
        self.peripheralsByUUID[uuid] = peripheral;
    }
    return peripheral;
}

- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    [self.mockDelegate mockCentralManager:self retrievePeripheralsWithIdentifiers:identifiers];
    NSMutableArray *peripherals = [NSMutableArray array];
    for (NSUUID *UUID in identifiers) {
        [peripherals addObject:[self peripheralForUUID:UUID]];
    }
    return peripherals;
}

- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs
{
    return [self.mockDelegate mockCentralManager:self retrieveConnectedPeripheralsWithServices:serviceUUIDs];
}

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options
{
    _isScanning = true;
    [self.mockDelegate mockCentralManager:self scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void)stopScan
{
    _isScanning = false;
    [self.mockDelegate mockCentralManagerStopScan:self];
}

- (void)connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options
{
    peripheral.state = CBPeripheralStateConnecting;
    [self.mockDelegate mockCentralManager:self connectPeripheral:peripheral options:options];
}

- (void)cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_9_0
    peripheral.state = CBPeripheralStateDisconnecting;
#endif
    [self.mockDelegate mockCentralManager:self cancelPeripheralConnection:peripheral];
}

- (void)performFakeAction:(void(^)(void))block
{
    @synchronized (self) {
        self.fakeActionCount += 1;
    }
    dispatch_async(self.queue, ^{
        block();
        @synchronized (self) {
            self.fakeActionCount -= 1;
        }
    });
}

- (void)fakeStateChange:(CBManagerState)state
{
    [self performFakeAction:^{
        self.state = state;
        [self.delegate centralManagerDidUpdateState:(id)self];
    }];
}

- (void)fakeScanPeripheralWithUUID:(NSUUID *)peripheralUUID
                           advInfo:(NSDictionary *)info
                              RSSI:(NSNumber *)RSSI
{
    RZBMockPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    [self performFakeAction:^{
        [self.delegate centralManager:(id)self didDiscoverPeripheral:(id)peripheral advertisementData:info RSSI:RSSI];
    }];
}

- (void)fakeConnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error
{
    RZBMockPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    [self performFakeAction:^{
        peripheral.state = error ? CBPeripheralStateDisconnected : CBPeripheralStateConnected;
        if (error) {
            [self.delegate centralManager:(id)self didFailToConnectPeripheral:(id)peripheral error:error];
        }
        else {
            [self.delegate centralManager:(id)self didConnectPeripheral:(id)peripheral];
        }
    }];
}

- (void)fakeDisconnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error
{
    RZBMockPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    [self performFakeAction:^{
        peripheral.state = CBPeripheralStateDisconnected;
        peripheral.services = @[];
        [self.delegate centralManager:(id)self didDisconnectPeripheral:(id)peripheral error:error];
    }];
}

@end
