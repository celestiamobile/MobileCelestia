// CelestiaSelection.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaAstroObject;
@class CelestiaStar;
@class CelestiaDSO;
@class CelestiaBody;
@class CelestiaLocation;
@class CelestiaUniversalCoord;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_SENDABLE
NS_SWIFT_NAME(Selection)
@interface CelestiaSelection : NSObject

@property (readonly, getter=isEmpty) BOOL empty;
@property (readonly) double radius;

@property (nullable, readonly) CelestiaAstroObject *object;
@property (nullable, readonly) CelestiaStar *star;
@property (nullable, readonly) CelestiaDSO *dso;
@property (nullable, readonly) CelestiaBody *body;
@property (nullable, readonly) CelestiaLocation *location;

- (BOOL)isEqualToSelection:(CelestiaSelection *)csel;
- (CelestiaUniversalCoord *)position:(double)t;

- (instancetype)init;
- (instancetype)initWithObject:(CelestiaAstroObject *)object;

@end

NS_ASSUME_NONNULL_END
