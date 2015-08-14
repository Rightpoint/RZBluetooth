//
//  ServiceListViewController.m
//  RZBluetoothExample
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "ServiceListViewController.h"
#import "ScanListViewController.h"
#import "RZBluetooth.h"

@import CoreBluetooth;

@interface ServiceViewModel : NSObject

@property (strong, nonatomic) CBUUID *serviceUUID;
@property (strong, nonatomic) Class viewControllerClass;

@end

@implementation ServiceViewModel
@end

@interface ServiceListViewController ()

@property (strong, nonatomic) NSArray *services;
@property (strong, nonatomic) RZBCentralManager *centralManager;

@end

@implementation ServiceListViewController

- (instancetype)init
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.centralManager = [[RZBCentralManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Service List";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    ServiceViewModel *heartRate = [[ServiceViewModel alloc] init];
    heartRate.serviceUUID = [CBUUID rzb_UUIDForHeartRateService];
    heartRate.viewControllerClass = NSClassFromString(@"HeartRateViewController");
    
    self.services = @[heartRate];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.services.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    ServiceViewModel *object = self.services[indexPath.row];
    cell.textLabel.text = object.serviceUUID.description;
    cell.detailTextLabel.text = [object.serviceUUID UUIDString];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ServiceViewModel *object = self.services[indexPath.row];
    ScanListViewController *scanViewController = [[ScanListViewController alloc] initWithScanUUID:object.serviceUUID
                                                                                   centralManager:self.centralManager
                                                                    discoveredViewControllerClass:object.viewControllerClass];
    [self.navigationController pushViewController:scanViewController animated:YES];
}

@end
