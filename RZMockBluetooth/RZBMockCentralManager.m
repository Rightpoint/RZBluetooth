//
//  RZBTestCentralManager.m
//  UMTSDK
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
        self.state = CBCentralManagerStateUnknown;
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

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options
{
    [self.mockDelegate mockCentralManager:self scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void)stopScan
{
    [self.mockDelegate mockCentralManagerStopScan:self];
}

- (void)connectPeripheral:(RZBMockPeripheral *)peripheral options:(NSDictionary *)options
{
    peripheral.state = CBPeripheralStateConnecting;
    [self.mockDelegate mockCentralManager:self connectPeripheral:peripheral options:options];
}

- (void)cancelPeripheralConnection:(RZBMockPeripheral *)peripheral
{
    [self.mockDelegate mockCentralManager:self cancelPeripheralConnection:peripheral];
}

- (void)fakeStateChange:(CBCentralManagerState)state
{
    dispatch_async(self.queue, ^{
        self.state = state;
        [self.delegate centralManagerDidUpdateState:(id)self];
    });
}

- (void)fakeScanPeripheralWithUUID:(NSUUID *)peripheralUUID
                           advInfo:(NSDictionary *)info
                              RSSI:(NSNumber *)RSSI
{
    RZBMockPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    dispatch_async(self.queue, ^{
        [self.delegate centralManager:(id)self didDiscoverPeripheral:(id)peripheral advertisementData:info RSSI:RSSI];
    });
}

- (void)fakeConnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error
{
    RZBMockPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    dispatch_async(self.queue, ^{
        peripheral.state = error ? CBPeripheralStateDisconnected : CBPeripheralStateConnected;
        if (error) {
            [self.delegate centralManager:(id)self didFailToConnectPeripheral:(id)peripheral error:error];
        }
        else {
            [self.delegate centralManager:(id)self didConnectPeripheral:(id)peripheral];
        }
    });
}

- (void)fakeDisconnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error
{
    RZBMockPeripheral *peripheral = [self peripheralForUUID:peripheralUUID];
    dispatch_async(self.queue, ^{
        peripheral.state = CBPeripheralStateDisconnected;
        [self.delegate centralManager:(id)self didDisconnectPeripheral:(id)peripheral error:error];
    });
}

@end
