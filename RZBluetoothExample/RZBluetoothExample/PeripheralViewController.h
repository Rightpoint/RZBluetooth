//
//  DetailViewController.h
//  RZBluetoothExample
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RZBluetooth.h"

@interface PeripheralViewController : UIViewController

- (instancetype)initWithPeripheral:(RZBPeripheral *)peripheral;

@property (strong, nonatomic, readonly) RZBPeripheral *peripheral;

@end

