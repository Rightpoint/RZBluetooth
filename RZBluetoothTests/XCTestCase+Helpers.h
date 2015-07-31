//
//  XCTestCase+Helpers.h
//  UMTSDK
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "CBCharacteristic+RZBExtension.h"
#import "RZBUUIDPath.h"
@class RZBCommandDispatch;

@interface XCTestCase (Helpers)

+ (NSUUID *)pUUID;
+ (CBUUID *)sUUID;
+ (CBUUID *)cUUID;

+ (NSUUID *)p2UUID;
+ (CBUUID *)s2UUID;
+ (CBUUID *)c2UUID;

+ (RZBUUIDPath *)pUUIDPath;
+ (RZBUUIDPath *)sUUIDPath;
+ (RZBUUIDPath *)cUUIDPath;

- (void)waitForQueueFlush;
- (void)waitForDispatch:(RZBCommandDispatch *)dispatch expectation:(XCTestExpectation *)expectation;

@end
