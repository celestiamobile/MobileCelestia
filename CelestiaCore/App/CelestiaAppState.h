// CelestiaAppState.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <CelestiaCore/CelestiaObserver.h>
#import <CelestiaCore/CelestiaSelection.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppState)
@interface CelestiaAppState : NSObject

@property (readonly) float speed;
@property (readonly) float timeScale;
@property (readonly) NSDate *time;

@property (readonly) BOOL showDistanceToSelection;
@property (readonly) BOOL showDistanceToSelectionCenter;
@property (readonly) double distanceToSelectionSurface;
@property (readonly) double distanceToSelectionCenter;

@property (readonly) CelestiaCoordinateSystem coordinateSystem;
@property (readonly) CelestiaSelection *referenceObject;
@property (readonly) CelestiaSelection *targetObject;
@property (readonly) CelestiaSelection *trackedObject;
@property (readonly) CelestiaSelection *selectedObject;

@property (readonly, getter=isPaused) BOOL paused;
@property (readonly, getter=isLightTravelDelayEnabled) BOOL lightTravelDelayEnabled;

@end

NS_ASSUME_NONNULL_END
