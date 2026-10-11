// CelestiaUniverse.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#include <celengine/body.h>
#include <celengine/location.h>
#import "CelestiaUniverse.h"
#import "CelestiaSelection+Private.h"
#import "CelestiaUniverse+Private.h"
#import "CelestiaDSOCatalog+Private.h"
#import "CelestiaStarCatalog+Private.h"

@interface CelestiaUniverse () {
    Universe *u;

    CelestiaDSOCatalog *_dsoCatalog;
    CelestiaStarCatalog *_starCatalog;
}

@end

@implementation CelestiaUniverse (Private)

- (instancetype)initWithUniverse:(Universe *)uni {
    self = [super init];
    if (self) {
        u = uni;

        _dsoCatalog = nil;
        _starCatalog = nil;
    }
    return self;
}

- (Universe *)universe {
    return u;
}

@end

@implementation CelestiaUniverse

- (NSString *)nameForSelection:(CelestiaSelection *)selection {
    const Selection sel = [selection selection];
    switch (sel.getType()) {
        case SelectionType::Star:
            return [NSString stringWithUTF8String:u->getStarCatalog()->getStarName(*sel.star(), true).c_str()];
        case SelectionType::Body:
            return [NSString stringWithUTF8String:sel.body()->getName(true).c_str()];
        case SelectionType::DeepSky:
            return [NSString stringWithUTF8String:u->getDSOCatalog()->getDSOName(sel.deepsky(), true).c_str()];
        case SelectionType::Location:
            return [NSString stringWithUTF8String:sel.location()->getName(true).c_str()];
        default:
            return @"";
    }
}

- (CelestiaDSOCatalog *)dsoCatalog {
    if (!_dsoCatalog) {
        _dsoCatalog = [[CelestiaDSOCatalog alloc] initWithDatabase:u->getDSOCatalog()];
    }
    return _dsoCatalog;
}

- (CelestiaStarCatalog *)starCatalog {
    if (!_starCatalog) {
        _starCatalog = [[CelestiaStarCatalog alloc] initWithDatabase:u->getStarCatalog()];
    }
    return _starCatalog;
}

- (BOOL)isSelectionMarked:(CelestiaSelection *)selection {
    return static_cast<BOOL>(u->isMarked([selection selection], 1));
}

- (void)markSelection:(CelestiaSelection *)selection withMarker:(CelestiaMarkerRepresentation)marker {
    u->markObject([selection selection], celestia::MarkerRepresentation(celestia::MarkerRepresentation::Symbol(marker), 10.0f, Color(0.0f, 1.0f, 0.0f, 0.9f)), 1);
}

- (void)unmarkSelection:(CelestiaSelection *)selection {
    u->unmarkObject([selection selection], 1);
}

- (void)unmarkAll {
    u->unmarkAll();
}

- (NSString *)webInfoURLForSelection:(CelestiaSelection *)selection {
    auto infoURL = u->getInfoURL([selection selection]);
    return infoURL.empty() ? nil : [NSString stringWithUTF8String:infoURL.data()];
}

@end
