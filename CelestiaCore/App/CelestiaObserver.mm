// CelestiaObserver.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaObserver.h"
#import "CelestiaObserver+Private.h"
#import "CelestiaSelection+Private.h"

@interface CelestiaObserver () {
    Observer *o;
}

@end

@implementation CelestiaObserver

- (NSString *)displayedSurface {
    return [NSString stringWithUTF8String:o->getDisplayedSurface().c_str()];
}

- (void)setDisplayedSurface:(NSString *)displayedSurface {
    o->setDisplayedSurface([displayedSurface UTF8String]);
}

- (CelestiaSelection *)cockpit {
    return [[CelestiaSelection alloc] initWithSelection:o->getCockpit()];
}

- (void)setCockpit:(CelestiaSelection *)cockpit {
    o->setCockpit([cockpit selection]);
}

- (void)setFrame:(CelestiaCoordinateSystem)coordinate target:(CelestiaSelection *)target reference:(CelestiaSelection *)reference {
    const Selection ref([reference selection]);
    const Selection tar([target selection]);
    o->setFrame(static_cast<ObserverFrame::CoordinateSystem>(coordinate), ref, tar);
}

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (void)rotate:(simd_quatf)from to:(simd_quatf)to {
    Eigen::Quaternionf f(to.vector[3], from.vector[0], from.vector[1], from.vector[2]);
    Eigen::Quaternionf t(to.vector[3], to.vector[0], to.vector[1], to.vector[2]);
    f.normalize();
    t.normalize();
    o->rotate(t * f.conjugate());
}
#endif

@end

@implementation CelestiaObserver (Private)

- (instancetype)initWithObserver:(Observer *)observer {
    self = [super init];
    if (self) {
        o = observer;
    }
    return self;
}

- (Observer *)observer {
    return o;
}

@end
