// CelestiaRotationModel.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaRotationModel+Private.h"
#import "CelestiaVector+Private.h"
#import "CelestiaUtil.h"

@interface CelestiaRotationModel () {
    const celestia::ephem::RotationModel *r;
}

@end

@implementation CelestiaRotationModel (Private)

- (instancetype)initWithRotation:(const celestia::ephem::RotationModel *)rotation {
    self = [super init];
    if (self) {
        r = rotation;
    }
    return self;
}

- (const celestia::ephem::RotationModel *)rotation {
    return r;
}

@end

@implementation CelestiaRotationModel

- (BOOL)isPeriodic {
    return static_cast<BOOL>(r->isPeriodic());
}

- (NSTimeInterval)period {
    return r->getPeriod();
}

- (double)validBeginTime {
    double beginTime = 0.0;
    double endTime = 0.0;
    r->getValidRange(beginTime, endTime);
    return beginTime;
}

- (double)validEndTime {
    double beginTime = 0.0;
    double endTime = 0.0;
    r->getValidRange(beginTime, endTime);
    return endTime;
}

- (CelestiaVector *)angularVelocityAtTime:(NSDate *)time {
    return [CelestiaVector vectorWithVector3d:r->angularVelocityAtTime([time julianDay])];
}

- (CelestiaVector *)equatorOrientationAtTime:(NSDate *)time {
    return [CelestiaVector vectorWithQuaterniond:r->equatorOrientationAtTime([time julianDay])];
}

- (CelestiaVector *)spinAtTime:(NSDate *)time {
    return [CelestiaVector vectorWithQuaterniond:r->spin([time julianDay])];
}

@end
