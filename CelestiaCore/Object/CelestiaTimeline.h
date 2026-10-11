// CelestiaTimeline.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaTimelinePhase;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Timeline)
@interface CelestiaTimeline : NSObject

@property (nonatomic, readonly) NSInteger phaseCount;

- (CelestiaTimelinePhase *)phaseAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
