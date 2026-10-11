// CelestiaBrowserItem.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaBrowserItem+Private.h"
#import "CelestiaStar.h"
#import "CelestiaBody.h"
#import "CelestiaDSO.h"
#import "CelestiaLocation.h"
#import "CelestiaUniverse.h"

@interface CelestiaBrowserItemKeyValuePair ()
@property (nonatomic) NSString *key;
@property (nonatomic) CelestiaBrowserItem *value;
@end

@implementation CelestiaBrowserItemKeyValuePair

- (instancetype)initWithName:(NSString *)name browserItem:(CelestiaBrowserItem *)browserItem {
    self = [super init];
    if (self) {
        _key = [name copy];
        _value = browserItem;
    }
    return self;
}

@end

@interface CelestiaBrowserItem ()

@property CelestiaAstroObject *catEntry;
@property NSString *stringValue;

@property (weak) id<CelestiaBrowserItemChildrenProvider> childrenProvider;

@property NSArray<NSString *> *childrenKeys;
@property NSArray<CelestiaBrowserItem *> *childrenValues;

@end

@implementation CelestiaBrowserItem

- (instancetype)initWithName:(NSString *)name
             alternativeName:(NSString *)alternativeName
                    catEntry:(CelestiaAstroObject *)entry
                    provider:(id<CelestiaBrowserItemChildrenProvider>)provider {
    self = [super init];
    if (self) {
        _stringValue = name;
        _alternativeName = alternativeName;
        _catEntry = entry;
        _childrenProvider = provider;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
             alternativeName:(NSString *)alternativeName
             orderedChildren:(NSArray<CelestiaBrowserItemKeyValuePair *> *)children {
    self = [super init];
    if (self) {
        _catEntry = nil;
        _stringValue = name;
        _alternativeName = alternativeName;
        _childrenProvider = nil;
        NSMutableArray *values = [NSMutableArray array];
        NSMutableArray *keys = [NSMutableArray array];
        for (CelestiaBrowserItemKeyValuePair *entry : children) {
            [keys addObject:entry.key];
            [values addObject:entry.value];
        }
        _childrenKeys = keys;
        _childrenValues = values;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
             alternativeName:(NSString *)alternativeName
                    children:(NSDictionary<NSString *, CelestiaBrowserItem *> *)children {
    self = [super init];
    if (self) {
        _catEntry = nil;
        _stringValue = name;
        _alternativeName = alternativeName;
        _childrenProvider = nil;
        _childrenKeys = [[children allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        NSMutableArray *values = [NSMutableArray array];
        for (NSString *key : _childrenKeys) {
            [values addObject:[children objectForKey:key]];
        }
        _childrenValues = values;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                    catEntry:(CelestiaAstroObject *)entry
                    provider:(id<CelestiaBrowserItemChildrenProvider>)provider {
    return [self initWithName:name alternativeName:nil catEntry:entry provider:provider];
}

- (instancetype)initWithName:(NSString *)name
                    children:(NSDictionary<NSString *, CelestiaBrowserItem *> *)children {
    return [self initWithName:name alternativeName:nil children:children];
}

- (instancetype)initWithName:(NSString *)name orderedChildren:(NSArray<CelestiaBrowserItemKeyValuePair *> *)children {
    return [self initWithName:name alternativeName:nil orderedChildren:children];
}

- (NSString *)name {
    return _stringValue;
}

- (CelestiaAstroObject *)entry {
    return _catEntry;
}

- (void)setChildren:(NSDictionary<NSString *, CelestiaBrowserItem *> *)children {
    _childrenKeys = [[children allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableArray *values = [NSMutableArray array];
    for (NSString *key : _childrenKeys) {
        [values addObject:[children objectForKey:key]];
    }
    _childrenValues = values;
    _childrenProvider = nil;
}

- (NSUInteger)childCount {
    if (_childrenValues == nil && _childrenProvider != nil)
        [self setChildren:[_childrenProvider childrenForBrowserItem:self]];

    return [_childrenValues count];
}

- (NSString *)childNameAt:(NSInteger)index {
    if (_childrenValues == nil && _childrenProvider != nil)
        [self setChildren:[_childrenProvider childrenForBrowserItem:self]];

    return [_childrenKeys objectAtIndex:index];
}

- (CelestiaBrowserItem *)childNamed:(NSString *)aName {
    if (_childrenValues == nil && _childrenProvider != nil)
        [self setChildren:[_childrenProvider childrenForBrowserItem:self]];

    NSUInteger index = [_childrenKeys indexOfObject:aName];
    if (index == NSNotFound)
        return nil;

    return [_childrenValues objectAtIndex:index];
}

- (NSArray<CelestiaBrowserItem *> *)children {
    if (_childrenValues == nil && _childrenProvider != nil)
        [self setChildren:[_childrenProvider childrenForBrowserItem:self]];

    if (_childrenValues)
        return [_childrenValues copy];
    return [NSArray array];
}

@end
