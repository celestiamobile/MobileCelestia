// CelestiaPlanetarySystem.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaBody;
@class CelestiaStar;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PlanetarySystem)
@interface CelestiaPlanetarySystem : NSObject

@property (nullable, readonly) CelestiaBody *primaryObject;
@property (nullable, readonly) CelestiaStar *star;

@end

NS_ASSUME_NONNULL_END
