//
//  RZTestCommands.h
//  RZBluetooth
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCommand.h"

@interface RZBPTestCommand : RZBCommand
@property (strong, nonatomic) NSUUID *peripheralUUID;
@property (assign, nonatomic) BOOL shouldExecute;
@end

@interface RZBSTestCommand : RZBPTestCommand
@property (strong, nonatomic) NSUUID *serviceUUID;
@end

@interface RZBCTestCommand : RZBPTestCommand
@property (strong, nonatomic) NSUUID *serviceUUID;
@property (strong, nonatomic) NSUUID *characteristicUUID;
@end

