//
//  RZBCentralManager+Mock.h
//  RZBluetooth
//
//  Created by Brian King on 3/28/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#import "RZBCentralManager.h"

@class RZBMockCentralManager;

NS_ASSUME_NONNULL_BEGIN

@interface RZBCentralManager (Mock)

@property (strong, nonatomic, readonly) RZBMockCentralManager *mockCentralManager;

@end

NS_ASSUME_NONNULL_END