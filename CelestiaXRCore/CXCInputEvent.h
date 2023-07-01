//
// CXCInputEvent.h
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import <Foundation/Foundation.h>
#import <Spatial/Spatial.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CXCInputEventPhase) {
    CXCInputEventPhaseActive,
    CXCInputEventPhaseCancelled,
    CXCInputEventPhaseEnded,
} NS_SWIFT_NAME(InputEventPhase);

NS_SWIFT_NAME(InputEvent)
@interface CXCInputEvent : NSObject

@property (readonly) CGPoint location;
@property (readonly) SPPoint3D location3D;
@property (readonly) SPRay3D selectionRay;
@property (readonly) CXCInputEventPhase phase;

- (instancetype)initWithLocation:(CGPoint)location location3D:(SPPoint3D)location3D selectionRay:(SPRay3D)selectionRay phase:(CXCInputEventPhase)phase;

@end

NS_ASSUME_NONNULL_END
