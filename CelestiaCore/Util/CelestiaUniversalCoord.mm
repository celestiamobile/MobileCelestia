// CelestiaUniversalCoord.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaUniversalCoord+Private.h"
#import "CelestiaVector+Private.h"

@interface CelestiaUniversalCoord () {
    UniversalCoord u;
}
@end

@implementation CelestiaUniversalCoord (Private)

- (instancetype)initWithUniversalCoord:(UniversalCoord)uni {
    self = [super init];
    if (self) {
        u = uni;
    }
    return self;
}

-(UniversalCoord)universalCoord {
    return u;
}

@end

@implementation CelestiaUniversalCoord

+ (CelestiaUniversalCoord *)zero {
    return [[CelestiaUniversalCoord alloc] initWithUniversalCoord:UniversalCoord::Zero()];
}

- (double)distanceFrom:(CelestiaUniversalCoord *) t {
    return u.distanceFromKm([t universalCoord]);
}

- (CelestiaVector *)offetFrom:(CelestiaUniversalCoord *)t {
    Eigen::Vector3d offset = u.offsetFromKm([t universalCoord]);
    return [CelestiaVector vectorWithVector3d:offset];
}

@end
