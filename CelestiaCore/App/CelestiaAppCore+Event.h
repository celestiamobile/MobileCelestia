// CelestiaAppCore+Event.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <CelestiaCore/CelestiaAppCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CelestiaEventModifier) {
    CelestiaEventModifierTouch = 0x40,
} NS_SWIFT_NAME(EventModifier);

@interface CelestiaAppCore (Event)

// MARK: Mouse events
- (void)mouseButtonUp:(CGPoint)location modifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons NS_SWIFT_NAME(mouseButtonUp(at:modifiers:with:));
- (void)mouseButtonDown:(CGPoint)location modifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons NS_SWIFT_NAME(mouseButtonDown(at:modifiers:with:));
- (void)mouseDragged:(CGPoint)location NS_SWIFT_NAME(mouseDragged(to:));
- (void)mouseMove:(CGPoint)offset modifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons NS_SWIFT_NAME(mouseMove(by:modifiers:with:));
- (void)mouseWheel:(CGFloat)motion modifiers:(NSUInteger)modifiers NS_SWIFT_NAME(mouseWheel(by:modifiers:));

// MARK: Key events
- (void)keyUp:(nullable NSString *)input modifiers:(NSUInteger)modifiers NS_SWIFT_NAME(keyUp(with:modifiers:));
- (void)keyDown:(nullable NSString *)input modifiers:(NSUInteger)modifiers NS_SWIFT_NAME(keyDown(with:modifiers:));
- (void)keyUp:(NSInteger)input;
- (void)keyDown:(NSInteger)input;
- (void)charEnter:(char)input;

// MARK: Joystick events
- (void)joystickButtonUp:(CelestiaJoystickButton)button;
- (void)joystickButtonDown:(CelestiaJoystickButton)button;
- (void)joystickAxis:(CelestiaJoystickAxis)axis amount:(float)amount;

- (void)pinchUpdate:(CGPoint)focus scale:(CGFloat)scale zoomFOV:(BOOL)zoomFOV;

@end

NS_ASSUME_NONNULL_END
