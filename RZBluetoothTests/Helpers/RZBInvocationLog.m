//
//  RZBCommandLog.m
//  RZBluetooth
//
//  Created by Brian King on 7/23/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBInvocationLog.h"

@interface RZBCommandLogEntry : NSObject

@property (assign, nonatomic) SEL selector;
@property (copy, nonatomic) NSArray *arguments;

@end

@implementation RZBCommandLogEntry

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ -- %@", NSStringFromSelector(self.selector), [self.arguments componentsJoinedByString:@", "]];
}

@end

@interface RZBInvocationLog ()
@property (strong, nonatomic) NSMutableArray *entries;
@end

@implementation RZBInvocationLog

+ (NSUInteger)argumentCountForSelector:(SEL)selector
{
    NSString *selectorString = NSStringFromSelector(selector);
    NSRange range = NSMakeRange(0, selectorString.length);
    NSUInteger argumentCount = [[selectorString mutableCopy] replaceOccurrencesOfString:@":"
                                                                             withString:@""
                                                                                options:0
                                                                                  range:range];
    return argumentCount;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.entries = [NSMutableArray array];
    }
    return self;
}

- (void)logSelector:(SEL)selector arguments:(id)firstObject, ...;
{
    va_list args;
    va_start(args, firstObject);
    id arg = firstObject;

    NSMutableArray *arguments = [NSMutableArray array];
    NSUInteger argCount = [self.class argumentCountForSelector:selector];
    for (NSUInteger i = 0; i < argCount; i++) {
        if (arg == nil) {
            [arguments addObject:[NSNull null]];
        }
        else {
            [arguments addObject:arg];
        }
        if (i + 1 < argCount) {
            arg = va_arg(args, id);
        }
    }
    va_end(args);
    RZBCommandLogEntry *entry = [[RZBCommandLogEntry alloc] init];
    entry.selector = selector;
    entry.arguments = arguments;
    [self.entries addObject:entry];
}

- (void)removeAllLogs
{
    [self.entries removeAllObjects];
}

- (NSArray *)entriesForSelector:(SEL)selector
{
    return [self.entries filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RZBCommandLogEntry *entry, NSDictionary *bindings) {
        return entry.selector == selector;
    }]];
}

- (NSArray *)argumentsForSelector:(SEL)selector;
{
    NSArray *entries = [self entriesForSelector:selector];
    NSAssert(entries.count <= 1, @"More than one entry found for selector %@", NSStringFromSelector(selector));
    return [(RZBCommandLogEntry *)entries.lastObject arguments];
}

- (id)argumentAtIndex:(NSUInteger)index forSelector:(SEL)selector
{
    return [[self argumentsForSelector:selector] objectAtIndex:index];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p entries=%@", self.class, self, self.entries];
}

@end
