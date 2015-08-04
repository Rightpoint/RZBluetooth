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
@class RZBSimulatedCallback;

typedef NSData*(^RZBReadAction)(void);
typedef void(^RZBWriteAction)(NSData *data);
typedef void(^RZBNotifyAction)(BOOL isNotifying);

@interface RZBSimulatedDevice : NSObject <RZBMockPeripheralDelegate>

@property (strong, nonatomic) RZBMockPeripheral *peripheral;
@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (copy, nonatomic) NSDictionary *advInfo;
@property (strong, nonatomic) NSNumber *RSSI;

@property (weak, nonatomic) id<CBPeripheralManagerDelegate>delegate;

@property (strong, nonatomic) NSArray *services;

@property (strong, nonatomic) NSMutableArray *readRequests;
@property (strong, nonatomic) NSMutableArray *writeRequests;

@property (strong, nonatomic) RZBSimulatedCallback *scanCallback;
@property (strong, nonatomic) RZBSimulatedCallback *connectCallback;
@property (strong, nonatomic) RZBSimulatedCallback *cancelConncetionCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverServiceCallback;
@property (strong, nonatomic) RZBSimulatedCallback *discoverCharacteristicCallback;

@property (strong, nonatomic) RZBSimulatedCallback *readCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *writeCharacteristicCallback;
@property (strong, nonatomic) RZBSimulatedCallback *notifyCharacteristicCallback;


- (void)respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result;
- (BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;

@end
