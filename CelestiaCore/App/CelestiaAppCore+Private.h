// CelestiaAppCore+Private.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CelestiaAppCore.h"
#include <celestia/celestiacore.h>

@interface CelestiaAppCore () {
    CelestiaCore *core;
};

@end

@interface CelestiaAppCore (Private)

// MARK: Mouse events
- (void)appCoreMouseButtonUp:(CGPoint)location modifiers:(int)modifiers;
- (void)appCoreMouseButtonDown:(CGPoint)location modifiers:(int)modifiers;
- (void)appCoreMouseDragged:(CGPoint)location;
- (void)appCoreMouseMove:(CGPoint)offset modifiers:(int)modifiers;
- (void)appCoreMouseWheel:(CGFloat)motion modifiers:(int)modifiers;

// MARK: Key events
- (void)appCoreKeyUp:(int)input modifiers:(int)modifiers;
- (void)appCoreKeyDown:(int)input modifiers:(int)modifiers;
- (void)appCoreCharEnter:(char)input modifiers:(int)modifiers;

// MARK: Joystick events
- (void)appCoreJoystickButtonUp:(int)button;
- (void)appCoreJoystickButtonDown:(int)button;
- (void)appCoreJoystickAxis:(CelestiaJoystickAxis)axis amount:(float)amount;

@end
