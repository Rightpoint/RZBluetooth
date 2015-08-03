//
//  RZBSimulatedDevice.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RZBMockPeripheral.h"

@class RZBMockCentralManager;
@class RZBSimulatedDevice;


typedef void(^RZBMockCentralManagerBlock)(RZBSimulatedDevice *device, RZBMockCentralManager *central);
typedef void(^RZBMockPeripheralBlock)(RZBSimulatedDevice *device, RZBMockPeripheral *peripheral);

@interface RZBSimulatedDevice : NSObject <RZBMockPeripheralDelegate>

@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (copy, nonatomic) NSDictionary *advInfo;
@property (strong, nonatomic) NSNumber *RSSI;

@property (copy, nonatomic) RZBMockCentralManagerBlock onScan;
@property (copy, nonatomic) RZBMockCentralManagerBlock onConnect;
@property (copy, nonatomic) RZBMockCentralManagerBlock onCancelConnection;


@property (strong, nonatomic) NSArray *services;

- (void)loadServices;

@end
