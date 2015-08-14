//
//  ScanListViewController.h
//  RZBluetoothExample
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZBluetooth.h"


@interface ScanListViewController : UITableViewController

- (instancetype)initWithScanUUID:(CBUUID *)scanUUID
                  centralManager:(RZBCentralManager *)centralManager
   discoveredViewControllerClass:(Class)discoveredViewControllerClass;

@end
