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

- (instancetype)initWithFocus:(SPVector3D)focus phase:(CXCInputEventPhase)phase {
    self = [super init];
    if (self) {
        _focus = focus;
        _phase = phase;
    }
    return self;
}

@end

@implementation CXCSingleTouchInputEvent

- (instancetype)initWithOldPose:(SPPose3D)oldPose newPose:(SPPose3D)newPose focus:(SPVector3D)focus phase:(CXCInputEventPhase)phase {
    self = [super initWithFocus:focus phase:phase];
    if (self) {
        _oldDirection = SPVector3DNormalize(SPVector3DMake(oldPose.position.x, oldPose.position.y, oldPose.position.z));
        _newDirection = SPVector3DNormalize(SPVector3DMake(newPose.position.x, newPose.position.y, newPose.position.z));
    }
    return self;
}

@end

@implementation CXCDoubleTouchInputEvent

- (instancetype)initWithOldPosition1:(SPPoint3D)oldPosition1 oldPosition2:(SPPoint3D)oldPosition2 newPosition1:(SPPoint3D)newPosition1 newPosition2:(SPPoint3D)newPosition2 focus:(SPVector3D)focus phase:(CXCInputEventPhase)phase {
    self = [super initWithFocus:focus phase:phase];
    if (self) {
        double oldDistance = SPPoint3DDistanceToPoint(oldPosition1, oldPosition2);
        double newDistance = SPPoint3DDistanceToPoint(newPosition1, newPosition2);
        _scale = newDistance / oldDistance;
    }
    return self;
}

@end
