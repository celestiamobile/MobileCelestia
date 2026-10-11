// CelestiaStar.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaStar.h"
#import "CelestiaStar+Private.h"
#import "CelestiaAstroObject+Private.h"
#import "CelestiaUniversalCoord+Private.h"
#import "CelestiaUtil.h"

@implementation CelestiaStar(Private)

- (instancetype)initWithStar:(Star *)star
{
    self = [super initWithObject:star];
    return self;
}

- (Star *)star {
    return reinterpret_cast<Star *>([self object]);
}

@end
/* 
    inline StellarClass getStellarClass() const;
    void setStellarClass(StellarClass);
*/
@implementation CelestiaStar

- (float)radius {
    return [self star]->getRadius();
}

- (float)absoluteMagnitude {
    return [self star]->getAbsoluteMagnitude();
}

- (NSString *)spectralType {
    return [NSString stringWithUTF8String:[self star]->getSpectralType()];
}

- (float)apparentMagnitude:(float)m {
    return [self star]->getApparentMagnitude(m);
}

- (void)setAbsoluteMagnitude:(float)m {
    [self star]->setAbsoluteMagnitude(m);
}

- (float)luminosity {
    return [self star]->getLuminosity();
}

- (float)temperature {
    return [self star]->getTemperature();
}

- (CelestiaUniversalCoord *)positionAtTime:(NSDate *)time {
    return [[CelestiaUniversalCoord alloc] initWithUniversalCoord:[self star]->getPosition([time julianDay])];
}

@end
