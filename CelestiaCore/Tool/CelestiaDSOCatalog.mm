// CelestiaDSOCatalog.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaDSOCatalog+Private.h"
#import "CelestiaDSO+Private.h"
#import "CelestiaGalaxy+Private.h"

#define BROWSER_MAX_DSO_COUNT   300

@interface CelestiaDSOCatalog () {
    DSODatabase *d;
}

@end

@implementation CelestiaDSOCatalog (Private)

- (instancetype)initWithDatabase:(DSODatabase *)database {
    self = [super init];
    if (self) {
        d = database;
    }
    return self;
}

- (DSODatabase *)database {
    return d;
}

@end

@implementation CelestiaDSOCatalog

- (NSInteger)count {
    return d->size();
}

- (CelestiaDSO *)objectAtIndex:(NSInteger)index {
    auto dso = d->getDSO(static_cast<uint32_t>(index));
    if (dso->getObjType() == DeepSkyObjectType::Galaxy)
        return [[CelestiaGalaxy alloc] initWithGalaxy:reinterpret_cast<Galaxy *>(dso)];
    return [[CelestiaDSO alloc] initWithDSO:dso];
}

- (NSString *)dsoName:(CelestiaDSO *)dso localized:(BOOL)localized {
    return [NSString stringWithUTF8String:d->getDSOName([dso DSO], static_cast<bool>(localized)).c_str()];
}

@end
