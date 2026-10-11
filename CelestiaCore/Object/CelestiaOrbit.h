// CelestiaOrbit.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaVector;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Orbit)
@interface CelestiaOrbit : NSObject

@property (readonly, getter=isPeriodic) BOOL periodic;
@property (readonly) NSTimeInterval period;
@property (readonly) double boundingRadius;

@property (readonly) double validBeginTime;
@property (readonly) double validEndTime;

- (CelestiaVector *)velocityAtTime:(NSDate *)time NS_SWIFT_NAME(velocity(at:));
- (CelestiaVector *)positionAtTime:(NSDate *)time NS_SWIFT_NAME(position(at:));

@end

NS_ASSUME_NONNULL_END
