//
//  ScanListViewController.m
//  RZBluetoothExample
//
//  Created by Brian King on 8/14/15.
//  Copyright © 2015 Raizlabs. All rights reserved.
//

#import "ScanListViewController.h"
#import "PeripheralViewController.h"

@interface ScanListViewController ()

@property (strong, nonatomic) NSMutableArray<RZBScanInfo *> *scannedDevices;
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

- (void)addScanInfo:(RZBScanInfo *)scanInfo {

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.centralManager scanForPeripheralsWithServices:@[self.scanUUID] options:@{} onDiscoveredPeripheral:^(RZBScanInfo *scanInfo, NSError *error) {
        if (error) {
            NSLog(@"Error scanning: %@", error);
            return;
        }
        __block NSUInteger existingIndex = 0;
        [self.scannedDevices enumerateObjectsUsingBlock:^(RZBScanInfo * info, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([info.peripheral.identifier isEqual:scanInfo.peripheral.identifier]) {
                info.advInfo = scanInfo.advInfo;
                info.RSSI = scanInfo.RSSI;
                existingIndex = idx;
            }
        }];

        NSLog(@"%@ - %@", [scanInfo.peripheral.identifier UUIDString], scanInfo.advInfo);

        if (existingIndex == NSNotFound) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.scannedDevices.count - 1 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:existingIndex inSection:0]]
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

    RZBScanInfo *object = self.scannedDevices[indexPath.row];
    cell.textLabel.text = object.peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RZBScanInfo *object = self.scannedDevices[indexPath.row];
    UIViewController *scanViewController = [[self.discoveredViewControllerClass alloc] initWithPeripheral:object.peripheral];
    [self.navigationController pushViewController:scanViewController animated:YES];
}


@end
