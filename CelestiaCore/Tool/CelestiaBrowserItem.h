// CelestiaBrowserItem.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaAstroObject;

NS_ASSUME_NONNULL_BEGIN

@class CelestiaBrowserItem;

NS_SWIFT_NAME(BrowserItemChildrenProvider)
@protocol CelestiaBrowserItemChildrenProvider <NSObject>
- (nullable NSDictionary<NSString *, CelestiaBrowserItem *> *)childrenForBrowserItem:(CelestiaBrowserItem *)item;
@end

NS_SWIFT_NAME(BrowserItemKeyValuePair)
@interface CelestiaBrowserItemKeyValuePair : NSObject
- (instancetype)initWithName:(NSString *)name browserItem:(CelestiaBrowserItem *)browserItem;
@end

NS_SWIFT_NAME(BrowserItem)
@interface CelestiaBrowserItem : NSObject

@property (nullable, readonly) NSString *alternativeName;
@property (readonly) NSString *name;
@property (nullable, readonly) CelestiaAstroObject *entry;
@property (readonly) NSArray<CelestiaBrowserItem *> *children;

- (instancetype)initWithName:(NSString *)name
             alternativeName:(nullable NSString *)alternativeName
                    catEntry:(CelestiaAstroObject *)entry
                    provider:(nullable id<CelestiaBrowserItemChildrenProvider>)provider;
- (instancetype)initWithName:(NSString *)name
                    catEntry:(CelestiaAstroObject *)entry
                    provider:(nullable id<CelestiaBrowserItemChildrenProvider>)provider;
- (instancetype)initWithName:(NSString *)name
             alternativeName:(nullable NSString *)alternativeName
                    children:(NSDictionary<NSString *, CelestiaBrowserItem *> *)children;
- (instancetype)initWithName:(NSString *)name
                    children:(NSDictionary<NSString *, CelestiaBrowserItem *> *)children;
- (instancetype)initWithName:(NSString *)name
             orderedChildren:(NSArray<CelestiaBrowserItemKeyValuePair *> *)children;
- (instancetype)initWithName:(NSString *)name
             alternativeName:(nullable NSString *)alternativeName
             orderedChildren:(NSArray<CelestiaBrowserItemKeyValuePair *> *)children;

- (void)setChildren:(NSDictionary<NSString *, CelestiaBrowserItem *> *)children;

- (nullable NSString *)childNameAt:(NSInteger)index NS_SWIFT_NAME(childName(at:));
- (nullable CelestiaBrowserItem *)childNamed: (NSString *)aName NS_SWIFT_NAME(child(with:));

@end

NS_ASSUME_NONNULL_END
