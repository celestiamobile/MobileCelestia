// CelestiaOrbit.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaOrbit+Private.h"
#import "CelestiaVector+Private.h"
#import "CelestiaUtil.h"

@interface CelestiaOrbit () {
    const celestia::ephem::Orbit *o;
}

@end

@implementation CelestiaOrbit (Private)

- (instancetype)initWithOrbit:(const celestia::ephem::Orbit *)orbit {
    self = [super init];
    if (self) {
        o = orbit;
    }
    return self;
}

- (const celestia::ephem::Orbit *)orbit {
    return o;
}

@end

@implementation CelestiaOrbit

- (double)boundingRadius {
    return o->getBoundingRadius();
}

- (BOOL)isPeriodic {
    return static_cast<BOOL>(o->isPeriodic());
}

- (NSTimeInterval)period {
    return o->getPeriod();
}

- (double)validBeginTime {
    double beginTime = 0.0;
    double endTime = 0.0;
    o->getValidRange(beginTime, endTime);
    return beginTime;
}

- (double)validEndTime {
    double beginTime = 0.0;
    double endTime = 0.0;
    o->getValidRange(beginTime, endTime);
    return endTime;
}

- (CelestiaVector *)positionAtTime:(NSDate *)time {
    return [CelestiaVector vectorWithVector3d:o->positionAtTime([time julianDay])];
}

- (CelestiaVector *)velocityAtTime:(NSDate *)time {
    return [CelestiaVector vectorWithVector3d:o->velocityAtTime([time julianDay])];
}

@end
