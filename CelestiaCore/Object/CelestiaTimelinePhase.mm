// CelestiaTimelinePhase.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#include <cmath>
#import "CelestiaUtil.h"
#import "CelestiaTimelinePhase+Private.h"

@interface CelestiaTimelinePhase () {
    double phaseStartTime;
    double phaseEndTime;
}
@end

@implementation CelestiaTimelinePhase

- (NSDate *)startTime {
    if (std::isinf(phaseStartTime))
        return nil;
    return [NSDate dateWithJulian:phaseStartTime];
}

- (NSDate *)endTime {
    if (std::isinf(phaseEndTime))
        return nil;
    return [NSDate dateWithJulian:phaseEndTime];
}

@end

@implementation CelestiaTimelinePhase (Private)

- (instancetype)initWithTimelinePhase:(const TimelinePhase&)timelinePhase {
    self = [super init];
    if (self) {
        phaseStartTime = timelinePhase.startTime();
        phaseEndTime = timelinePhase.endTime();
    }
    return self;
}

@end
