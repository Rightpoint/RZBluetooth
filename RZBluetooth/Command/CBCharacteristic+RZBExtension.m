//
//  CBCharacteristic+RZBExtension.m
//  UMTSDK
//
//  Created by Brian King on 7/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBCharacteristic+RZBExtension.h"
@import ObjectiveC.runtime;

@implementation CBCharacteristic (RZBExtension)

- (RZBCharacteristicCallback)rzb_notificationBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRzb_notificationBlock:(RZBCharacteristicCallback)notificationBlock
{
    objc_setAssociatedObject(self, @selector(rzb_notificationBlock), notificationBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end