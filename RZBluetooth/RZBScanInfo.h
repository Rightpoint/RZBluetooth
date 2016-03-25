//
//  RZBScanInfo.h
//  RZBluetooth
//
//  Created by Brian King on 3/25/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RZBPeripheral;

NS_ASSUME_NONNULL_BEGIN

@interface RZBScanInfo : NSObject

@property (strong, nonatomic) RZBPeripheral *peripheral;
@property (strong, nonatomic) NSNumber *RSSI;
@property (copy, nonatomic) NSDictionary *advInfo;

@end

NS_ASSUME_NONNULL_END
