// CelestiaStarCatalog.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaStarCatalog+Private.h"
#import "CelestiaStar+Private.h"

@interface CelestiaStarCatalog () {
    StarDatabase *d;
}

@end

@implementation CelestiaStarCatalog (Private)

- (instancetype)initWithDatabase:(StarDatabase *)database {
    self = [super init];
    if (self) {
        d = database;
    }
    return self;
}

- (StarDatabase *)database {
    return d;
}

@end

@implementation CelestiaStarCatalog

- (NSInteger)count {
    return d->size();
}

- (CelestiaStar *)objectAtIndex:(NSInteger)index {
    return [[CelestiaStar alloc] initWithStar:d->getStar(static_cast<uint32_t>(index))];
}

- (NSString *)starName:(CelestiaStar *)star localized:(BOOL)localized {
    Star *s = [star star];
    return [NSString stringWithUTF8String:d->getStarName(*s, static_cast<bool>(localized)).c_str()];
}

@end
