//
//  RZTestCommands.h
//  UMTSDK
//
//  Created by Brian King on 7/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBCommand.h"

@interface RZBPTestCommand : RZBCommand
@property (strong, nonatomic) NSUUID *peripheralUUID;
@end

@interface RZBSTestCommand : RZBCommand
@property (strong, nonatomic) NSUUID *peripheralUUID;
@property (strong, nonatomic) NSUUID *serviceUUID;
@end

@interface RZBCTestCommand : RZBCommand
@property (strong, nonatomic) NSUUID *peripheralUUID;
@property (strong, nonatomic) NSUUID *serviceUUID;
@property (strong, nonatomic) NSUUID *characteristicUUID;
@end

