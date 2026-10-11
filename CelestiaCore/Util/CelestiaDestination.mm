// CelestiaDestination.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaDestination+Private.h"

@implementation CelestiaDestination

@end

@implementation CelestiaDestination (Private)

- (instancetype)initWithDestination:(const Destination *)destination {
    self = [super init];
    if (self) {
        _name = [NSString stringWithUTF8String:destination->name.c_str()];
        _target = [NSString stringWithUTF8String:destination->target.c_str()];
        _distance = destination->distance;
        _content = [NSString stringWithUTF8String:destination->description.c_str()];
    }
    return self;
}

@end
