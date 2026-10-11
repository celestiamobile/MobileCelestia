// CelestiaAppCore+Render.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CelestiaAppCore+Render.h"
#import "CelestiaAppCore+Private.h"

#include <celestia/helper.h>

@implementation CelestiaAppCore (Render)

- (NSString *)renderInfo {
    return [NSString stringWithUTF8String:Helper::getRenderInfo(core->getRenderer()).c_str()];
}

@end
