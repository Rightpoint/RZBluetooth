//
//  RZBMockedCentralManager.h
//  RZBluetooth
//
//  Created by Brian King on 4/8/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

@import CoreBluetooth;

@protocol RZBMockCentralManagerDelegate, RZBMockedPeripheral;


@protocol RZBMockedCentralManager <NSObject>

- (CBPeripheral<RZBMockedPeripheral> *)peripheralForUUID:(NSUUID *)uuid;

@property(weak, nonatomic) id<RZBMockCentralManagerDelegate> mockDelegate;
@property(strong, nonatomic) dispatch_queue_t queue;

- (void)fakeStateChange:(CBCentralManagerState)state;
- (void)fakeScanPeripheralWithUUID:(NSUUID *)peripheralUUID advInfo:(NSDictionary *)info RSSI:(NSNumber *)RSSI;

- (void)fakeConnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error;
- (void)fakeDisconnectPeripheralWithUUID:(NSUUID *)peripheralUUID error:(NSError *)error;

@end

@protocol RZBMockCentralManagerDelegate <NSObject>

- (void)mockCentralManager:(CBCentralManager<RZBMockedCentralManager> *)mockCentralManager retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
- (void)mockCentralManager:(CBCentralManager<RZBMockedCentralManager> *)mockCentralManager scanForPeripheralsWithServices:(NSArray *)services options:(NSDictionary *)options;
- (void)mockCentralManagerStopScan:(CBCentralManager<RZBMockedCentralManager> *)mockCentralManager;

- (void)mockCentralManager:(CBCentralManager<RZBMockedCentralManager> *)mockCentralManager connectPeripheral:(CBPeripheral<RZBMockedPeripheral> *)peripheral options:(NSDictionary *)options;
- (void)mockCentralManager:(CBCentralManager<RZBMockedCentralManager> *)mockCentralManager cancelPeripheralConnection:(CBPeripheral<RZBMockedPeripheral> *)peripheral;

@end