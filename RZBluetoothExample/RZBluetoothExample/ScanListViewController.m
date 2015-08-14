//
//  ScanListViewController.m
//  RZBluetoothExample
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "ScanListViewController.h"
#import "PeripheralViewController.h"

@interface ScanListViewModel : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) NSNumber *RSSI;
@property (strong, nonatomic) NSDictionary *advInfo;


@end

@implementation ScanListViewModel


@end

@interface ScanListViewController ()

@property (strong, nonatomic) NSMutableArray *scannedDevices;
@property (strong, nonatomic) RZBCentralManager *centralManager;
@property (strong, nonatomic) CBUUID *scanUUID;
@property (strong, nonatomic) Class discoveredViewControllerClass;

@end

@implementation ScanListViewController

- (instancetype)initWithScanUUID:(CBUUID *)scanUUID
                  centralManager:(RZBCentralManager *)centralManager
   discoveredViewControllerClass:(Class)discoveredViewControllerClass;
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.title = [NSString stringWithFormat:@"Scan for %@", scanUUID];
        self.centralManager = centralManager;
        self.scanUUID = scanUUID;
        self.scannedDevices = [NSMutableArray array];
        self.discoveredViewControllerClass = discoveredViewControllerClass;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (ScanListViewModel *)scanListViewModelForPeripheral:(CBPeripheral *)peripheral
{
    for (ScanListViewModel *viewModel in self.scannedDevices) {
        if ([viewModel.peripheral.identifier isEqual:peripheral.identifier]) {
            return viewModel;
        }
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.centralManager scanForPeripheralsWithServices:@[self.scanUUID] options:@{} onDiscoveredPeripheral:^(CBPeripheral *peripheral, NSDictionary *advInfo, NSNumber *RSSI) {
        ScanListViewModel *viewModel = [self scanListViewModelForPeripheral:peripheral];
        NSUInteger index = [self.scannedDevices indexOfObject:viewModel];
        if (viewModel == nil) {
            viewModel = [[ScanListViewModel alloc] init];
            viewModel.peripheral = peripheral;
        }
        viewModel.advInfo = advInfo;
        viewModel.RSSI = RSSI;
        NSLog(@"%@ - %@", [peripheral.identifier UUIDString], advInfo);

        if (index == NSNotFound) {
            [self.scannedDevices addObject:viewModel];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.scannedDevices.count - 1 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.centralManager stopScan];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.scannedDevices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    ScanListViewModel *object = self.scannedDevices[indexPath.row];
    cell.textLabel.text = object.peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScanListViewModel *object = self.scannedDevices[indexPath.row];
    UIViewController *scanViewController = [[self.discoveredViewControllerClass alloc] initWithPeripheral:object.peripheral];
    [self.navigationController pushViewController:scanViewController animated:YES];
}


@end
