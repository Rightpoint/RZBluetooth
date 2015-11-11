//
//  RZBCentralManagerState.h
//  RZBluetooth
//
//  Created by Brian King on 11/11/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RZBPeripheralState;

@interface RZBCentralManagerState : NSObject

- (RZBPeripheralState *)stateForIdentifier:(NSUUID *)identifier;

@end
