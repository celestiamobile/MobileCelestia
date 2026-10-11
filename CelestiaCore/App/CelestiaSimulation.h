// CelestiaSimulation.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>
#import <CelestiaCore/CelestiaObserver.h>
#include <simd/simd.h>

@class CelestiaCompletion;
@class CelestiaSelection;
@class CelestiaUniverse;
@class CelestiaUniversalCoord;
@class CelestiaObserver;
@class CelestiaEclipse;
@class CelestiaDestination;

typedef NS_ENUM(NSUInteger, CelestiaSimulationDistanceUnit) {
    CelestiaSimulationDistanceUnitKM = 0,
    CelestiaSimulationDistanceUnitRadii = 1,
    CelestiaSimulationDistanceUnitAU = 2,
} NS_SWIFT_NAME(DistanceUnit);

typedef NS_ENUM(NSUInteger, CelestiaEclipseAction) {
    CelestiaEclipseActionSetTime = 0,
    CelestiaEclipseActionNearEclipsedBody = 1,
    CelestiaEclipseActionFromEclipsedBodySurface = 2,
    CelestiaEclipseActionFromOcculterSurface = 3,
    CelestiaEclipseActionBehindOcculter = 4,
} NS_SWIFT_NAME(EclipseAction);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_SENDABLE
NS_SWIFT_NAME(GoToLocation)
@interface CelestiaGoToLocation : NSObject

@property (readonly) CelestiaSelection *selection;
@property (readonly) float longitude;
@property (readonly) float latitude;
@property (readonly) double distance;
@property (readwrite) double duration;

- (instancetype)initWithSelection:(CelestiaSelection *)selection longitude:(float)longitude latitude:(float)latitude distance:(double)distance unit:(CelestiaSimulationDistanceUnit)unit;
- (instancetype)initWithSelection:(CelestiaSelection *)selection longitude:(float)longitude latitude:(float)latitude;
- (instancetype)initWithSelection:(CelestiaSelection *)selection distance:(double)distance unit:(CelestiaSimulationDistanceUnit)unit;
- (instancetype)initWithSelection:(CelestiaSelection *)selection;

@end

NS_SWIFT_NAME(Simulation)
@interface CelestiaSimulation : NSObject

@property (nonatomic) CelestiaSelection *selection;
@property (nonatomic) NSDate *time;
@property (nonatomic) double julianDay;

@property (readonly) CelestiaObserver *activeObserver;

@property (nullable, readonly) CelestiaGoToLocation *currentLocation;

@property (readonly) CelestiaUniverse *universe;

@property (nonatomic) simd_quatf observerQuaternion;

- (CelestiaSelection *)findObjectFromPath:(NSString *)path NS_SWIFT_NAME(findObject(from:));

- (void)reverseObserverOrientation;

- (void)goToLocation:(CelestiaGoToLocation *)location NS_SWIFT_NAME(go(to:));

- (void)performEclipseAction:(CelestiaEclipseAction)action eclipse:(CelestiaEclipse *)eclipse NS_SWIFT_NAME(performEclipseAction(_:eclipse:));

- (void)goToDestination:(CelestiaDestination *)destination NS_SWIFT_NAME(goToDestination(_:));

- (NSArray<CelestiaCompletion *> *)completionForName:(NSString *)name NS_SWIFT_NAME(completion(for:));

@end

NS_ASSUME_NONNULL_END
