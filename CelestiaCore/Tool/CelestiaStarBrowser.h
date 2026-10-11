// CelestiaStarBrowser.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaObserver;
@class CelestiaStar;
@class CelestiaUniverse;

typedef NS_ENUM(NSUInteger, CelestiaStarBrowserKind) {
    CelestiaStarBrowserKindNearest = 0,
    CelestiaStarBrowserKindBrighter = 1,
    CelestiaStarBrowserKindBrightest = 2,
    CelestiaStarBrowserKindStarsWithPlants = 3,
} NS_SWIFT_NAME(StarBrowserKind);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(StarBrowser)
@interface CelestiaStarBrowser : NSObject

- (instancetype)initWithKind:(CelestiaStarBrowserKind)kind observer:(CelestiaObserver *)observer universe:(CelestiaUniverse *)universe;

- (NSArray<CelestiaStar *> *)stars;

@end

NS_ASSUME_NONNULL_END
