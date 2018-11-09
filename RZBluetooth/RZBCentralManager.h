//
//  RZCentralManager.h
//  RZBluetooth
//
//  Created by Brian King on 7/22/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBDefines.h"

@class RZBPeripheral;

NS_ASSUME_NONNULL_BEGIN

/**
 * RZCentralManager encapsulates all delegate interactions, exposing only the high
 * level Bluetooth actions. RZCentralManager will automatically connect, and
 * discover any needed services or characteristics. It will also wait for 
 * Core Bluetooth to become available, and even re-submit any commands if the 
 * CoreBluetooth process crashes.
 */
@interface RZBCentralManager : NSObject

/**
 * Create a new central manager on the main dispatch queue, with a default identifier.
 */
- (instancetype)init;

/**
 * Create a new central manager
 *
 * @param identifier the restore identifier.
 * @param queue the dispatch queue for the central to use. The main queue will be used if queue is nil.
 *              It is important that the dispatch queue be a serial queue
 *
 */
- (instancetype)initWithIdentifier:(NSString *)identifier queue:(dispatch_queue_t __nullable)queue;

/**
 * Create a new central manager
 *
 * @param identifier the restore identifier.
 * @param peripheralClass the subclass of RZBPeripheral to use
 * @param queue the dispatch queue for the central to use. The main queue will be used if queue is nil.
 *              It is important that the dispatch queue be a serial queue
 */
- (instancetype)initWithIdentifier:(NSString *)identifier peripheralClass:(Class)peripheralClass queue:(dispatch_queue_t __nullable)queue;

/**
 * Create a new central manager
 *
 * @param identifier the restore identifier.
 * @param peripheralClass the subclass of RZBPeripheral to use
 * @param queue the dispatch queue for the central to use. The main queue will be used if queue is nil.
 *              It is important that the dispatch queue be a serial queue
 * @param options An optional dictionary containing initialization options for a core bluetooth central manager. For available options, see Core Bluetooth Central Manager Initialization Options.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier peripheralClass:(Class)peripheralClass queue:(dispatch_queue_t __nullable)queue options:(nullable NSDictionary<NSString *,id> *)options;

/**
 * Expose the backing CBManagerState. See RZBluetoothErrorForState to generate an
 * error object representing the non-functioning terminal states.
 */
@property (assign, nonatomic, readonly) CBManagerState state;

/**
 * This block will be triggered whenever the central manager state changes.
 * You can also use NSNotificationCenter to watch for notifications named RZBCentralManagerStateChangeNotification.
 */
@property (nonatomic, copy) RZBStateBlock centralStateHandler;

/**
 * This block will be triggered when restored with an array of RZBPeripheral objects.
 * You can also use NSNotificationCenter to watch for notifications named RZBCentralManagerRestorePeripheralNotification.
 *
 * To support state restoriation, you need to enable the 'Uses Bluetooth LE accessories' background mode.
 */
@property (nonatomic, copy) RZBRestorationBlock restorationHandler;

/**
 * Helper to get a peripheral from a peripheralUUID
 *
 * This method will return nil if passed a UUID that is not registered with CoreBluetooth.
 * This can happen if the UUID of a bonded peripheral is persisted, but the device
 * bonding is reset by either the phone or by the peripheral.
 */
- (RZBPeripheral * _Nullable)peripheralForUUID:(NSUUID *)peripheralUUID;

/**
 * Scan for peripherals with the specified UUIDs and options. Trigger the scanBlock
 * for every discovered peripheral. Multiple calls to this method will replace the previous
 * calls. 
 *
 * The onError: block will be triggered if there are any CBManagerState errors and
 * for user interaction timeout errors if configured.
 */
- (void)scanForPeripheralsWithServices:(NSArray<CBUUID *> * __nullable)serviceUUIDs
                               options:(NSDictionary<NSString *, id> * __nullable)options
                onDiscoveredPeripheral:(RZBScanBlock)scanBlock;

/**
 * Stop the peripheral scan.
 */
- (void)stopScan;

/**
 * Retrieve already-connected peripherals advertising the given service UUIDs.
 */
- (NSArray<RZBPeripheral *> *)retrieveConnectedPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs;

/**
 * Retrieve list of known peripherals by their identifiers.
 *
 * NOTE: This method will only return peripherals for the valid UUIDs passed in,
 *       and the returned array may have a different length than the input array.
 *       See peripheralForUUID: for more details.
 */
- (NSArray<RZBPeripheral *> *)retrievePeripheralsWithIdentifiers:(NSArray<NSUUID *> *)identifiers;

/**
 * This is the CoreBluetooth central manager that backs this central manager.
 * This is exposed for informational and testing purposes only. Directly invoking
 * methods on this object may cause un-expected behavior.
 */
@property (strong, nonatomic, readonly) CBCentralManager *coreCentralManager;

@end

/**
 * This notification is posted every time the state changes on the central manager.
 * The object is the RZBCentralManager object associated with the state change.
 */
extern NSString *const RZBCentralManagerStateChangeNotification;

/**
 * This notification is posted when state restoration restores peripherals.
 * The object is the RZBCentralManager object associated with the state change.
 * The RZBPeripheral objects that were restored are in the userInfo dictionary
 * behind the RZBCentralManagerPeripheralKey.
 */
extern NSString *const RZBCentralManagerRestorePeripheralNotification;
extern NSString *const RZBCentralManagerPeripheralKey;

NS_ASSUME_NONNULL_END
