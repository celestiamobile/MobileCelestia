// CelestiaTimeline+Private.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#include <celengine/timeline.h>
#import "CelestiaTimeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface CelestiaTimeline (Private)

- (instancetype)initWithTimeline:(const Timeline *)timeline;

@end

NS_ASSUME_NONNULL_END
