// CelestiaAppCore+Private.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CelestiaAppCore+Private.h"

@implementation CelestiaAppCore (Private)

// MARK: Mouse events
- (void)appCoreMouseButtonUp:(CGPoint)location modifiers:(int)modifiers {
    core->mouseButtonUp(location.x, location.y, modifiers);
}

- (void)appCoreMouseButtonDown:(CGPoint)location modifiers:(int)modifiers {
    core->mouseButtonDown(location.x, location.y, modifiers);
}

- (void)appCoreMouseDragged:(CGPoint)location {
    core->mouseMove(location.x, location.y);
}

- (void)appCoreMouseMove:(CGPoint)offset modifiers:(int)modifiers {
    core->mouseMove(offset.x, offset.y, modifiers);
}

- (void)appCoreMouseWheel:(CGFloat)motion modifiers:(int)modifiers {
    core->mouseWheel(motion, modifiers);
}

// MARK: Key events
- (void)appCoreKeyUp:(int)input modifiers:(int)modifiers {
    core->keyUp(input, modifiers);
}

- (void)appCoreKeyDown:(int)input modifiers:(int)modifiers {
    core->keyDown(input, modifiers);
}

- (void)appCoreCharEnter:(char)input modifiers:(int)modifiers {
    core->charEntered(input, modifiers);
}

// MARK: Joystick events
- (void)appCoreJoystickButtonUp:(int)button {
    core->joystickButton(button, false);
}

- (void)appCoreJoystickButtonDown:(int)button {
    core->joystickButton(button, true);
}

- (void)appCoreJoystickAxis:(CelestiaJoystickAxis)axis amount:(float)amount {
    core->joystickAxis(static_cast<CelestiaCore::JoyAxis>(axis), amount);
}
@end
