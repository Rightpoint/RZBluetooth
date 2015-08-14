//
//  HeartRateViewController.m
//  RZBluetoothExample
//
//  Created by Brian King on 8/14/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "HeartRateViewController.h"

@interface HeartRateViewController ()

@property (weak, nonatomic) IBOutlet UILabel *heartRate;

@end

@implementation HeartRateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.peripheral rzb_addHeartRateObserver:^(RZBHeartRateMeasurement *measurement, NSError *error) {
        self.heartRate.text = [NSString stringWithFormat:@"%lu", (unsigned long) measurement.heartRate];
        NSLog(@"%@", measurement);
    } completion:^(NSError *error) {
        NSLog(@"Error=%@", error);
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

@end
