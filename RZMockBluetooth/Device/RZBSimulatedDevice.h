//
//  RZBSimulatedDevice.h
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>


@interface RZBSimulatedDevice : NSObject

@property (strong, nonatomic, readonly) NSUUID *identifier;
@property (strong, nonatomic) NSNumber *RSSI;
@property (strong, nonatomic) NSDictionary *advInfo;

@property (assign, nonatomic) BOOL connectable;
@property (assign, nonatomic) BOOL discoverable;

@property (strong, nonatomic) NSArray *services;

- (void)loadServices;

@end
