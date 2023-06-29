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
    CXCInputEventPhaseEnded,
} NS_SWIFT_NAME(InputEventPhase);

NS_SWIFT_NAME(InputEvent)
@interface CXCInputEvent : NSObject

@property (readonly, nonatomic) SPVector3D focus;
@property (readonly, nonatomic) CXCInputEventPhase phase;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_SWIFT_NAME(SingleTouchInputEvent)
@interface CXCSingleTouchInputEvent : CXCInputEvent

@property (readonly, nonatomic) SPVector3D oldDirection;
@property (readonly, nonatomic) SPVector3D newDirection;

- (instancetype)initWithOldPose:(SPPose3D)oldPose newPose:(SPPose3D)newPose focus:(SPVector3D)focus phase:(CXCInputEventPhase)phase;

@end

NS_SWIFT_NAME(DoubleTouchInputEvent)
@interface CXCDoubleTouchInputEvent : CXCInputEvent

@property (readonly, nonatomic) double scale;

- (instancetype)initWithOldPosition1:(SPPoint3D)oldPosition1 oldPosition2:(SPPoint3D)oldPosition2 newPosition1:(SPPoint3D)newPosition1 newPosition2:(SPPoint3D)newPosition2 focus:(SPVector3D)focus phase:(CXCInputEventPhase)phase;

@end

NS_ASSUME_NONNULL_END
