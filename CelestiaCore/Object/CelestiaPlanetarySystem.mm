// CelestiaPlanetarySystem.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaPlanetarySystem+Private.h"
#import "CelestiaBody+Private.h"
#import "CelestiaStar+Private.h"

@interface CelestiaPlanetarySystem () {
    PlanetarySystem *s;
}

@end

@implementation CelestiaPlanetarySystem (Private)

- (instancetype)initWithSystem:(PlanetarySystem *)system {
    self = [super init];
    if (self) {
        s = system;
    }
    return self;
}

- (PlanetarySystem *)system {
    return s;
}

@end

@implementation CelestiaPlanetarySystem

- (CelestiaBody *)primaryObject {
    Body *b = s->getPrimaryBody();
    if (b == nullptr) {
        return nil;
    }
    return [[CelestiaBody alloc] initWithBody:b];
}

- (CelestiaStar *)star {
    Star *b = s->getStar();
    if (b == nullptr) {
        return nil;
    }
    return [[CelestiaStar alloc] initWithStar:b];
}

@end
