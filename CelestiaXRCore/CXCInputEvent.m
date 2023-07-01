//
// CXCInputEvent.m
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CXCInputEvent.h"

@implementation CXCInputEvent

- (instancetype)initWithLocation:(CGPoint)location location3D:(SPPoint3D)location3D selectionRay:(SPRay3D)selectionRay phase:(CXCInputEventPhase)phase {
    self = [super init];
    if (self) {
        _location = location;
        _location3D = location3D;
        _selectionRay = selectionRay;
        _phase = phase;
    }
    return self;
}

@end
