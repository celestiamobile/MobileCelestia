// CelestiaObserver.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <simd/simd.h>
#endif

@class CelestiaSelection;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CelestiaCoordinateSystem) {
    CelestiaCoordinateSystemUniversal = 0,
    CelestiaCoordinateSystemEcliptical = 1,
    CelestiaCoordinateSystemEquatorial = 2,
    CelestiaCoordinateSystemBodyFixed = 3,
    CelestiaCoordinateSystemPhaseLock = 5,
    CelestiaCoordinateSystemChase = 6,
    CelestiaCoordinateSystemPhaseLock_Old = 100,
    CelestiaCoordinateSystemChase_Old = 101,
    CelestiaCoordinateSystemObserverLocal = 200,
    CelestiaCoordinateSystemUnknown = 1000,
} NS_SWIFT_NAME(CoordinateSystem);

NS_SWIFT_NAME(Observer)
@interface CelestiaObserver : NSObject

@property (nonatomic) NSString *displayedSurface;
@property (nonatomic) CelestiaSelection *cockpit;

- (void)setFrame:(CelestiaCoordinateSystem)coordinate target:(CelestiaSelection *)target reference:(CelestiaSelection *)reference NS_SWIFT_NAME(setFrame(coordinate:target:reference:));
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (void)rotate:(simd_quatf)from to:(simd_quatf)to NS_SWIFT_NAME(rotate(from:to:));
#endif

@end

NS_ASSUME_NONNULL_END
