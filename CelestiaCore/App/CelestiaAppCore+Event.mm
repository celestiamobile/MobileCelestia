// CelestiaAppCore+Event.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CelestiaAppCore+Event.h"
#import "CelestiaAppCore+Private.h"

#import <TargetConditionals.h>

#if !TARGET_OS_OSX
#import <UIKit/UICommand.h>

#define NSEventModifierFlagCommand        UIKeyModifierCommand
#define NSEventModifierFlagControl        UIKeyModifierControl
#define NSEventModifierFlagShift          UIKeyModifierShift
#define NSEventModifierFlagNumericPad     UIKeyModifierNumericPad

enum {
    NSEnterCharacter                = 0x0003,
    NSBackspaceCharacter            = 0x0008,
    NSTabCharacter                  = 0x0009,
    NSNewlineCharacter              = 0x000a,
    NSFormFeedCharacter             = 0x000c,
    NSCarriageReturnCharacter       = 0x000d,
    NSBackTabCharacter              = 0x0019,
    NSDeleteCharacter               = 0x007f,
    NSLineSeparatorCharacter        = 0x2028,
    NSParagraphSeparatorCharacter   = 0x2029,
};

enum {
    NSUpArrowFunctionKey        = 0xF700,
    NSDownArrowFunctionKey      = 0xF701,
    NSLeftArrowFunctionKey      = 0xF702,
    NSRightArrowFunctionKey     = 0xF703,
    NSF1FunctionKey             = 0xF704,
    NSF2FunctionKey             = 0xF705,
    NSF3FunctionKey             = 0xF706,
    NSF4FunctionKey             = 0xF707,
    NSF5FunctionKey             = 0xF708,
    NSF6FunctionKey             = 0xF709,
    NSF7FunctionKey             = 0xF70A,
    NSF8FunctionKey             = 0xF70B,
    NSF9FunctionKey             = 0xF70C,
    NSF10FunctionKey            = 0xF70D,
    NSF11FunctionKey            = 0xF70E,
    NSF12FunctionKey            = 0xF70F,
    NSF13FunctionKey            = 0xF710,
    NSF14FunctionKey            = 0xF711,
    NSF15FunctionKey            = 0xF712,
    NSF16FunctionKey            = 0xF713,
    NSF17FunctionKey            = 0xF714,
    NSF18FunctionKey            = 0xF715,
    NSF19FunctionKey            = 0xF716,
    NSF20FunctionKey            = 0xF717,
    NSF21FunctionKey            = 0xF718,
    NSF22FunctionKey            = 0xF719,
    NSF23FunctionKey            = 0xF71A,
    NSF24FunctionKey            = 0xF71B,
    NSF25FunctionKey            = 0xF71C,
    NSF26FunctionKey            = 0xF71D,
    NSF27FunctionKey            = 0xF71E,
    NSF28FunctionKey            = 0xF71F,
    NSF29FunctionKey            = 0xF720,
    NSF30FunctionKey            = 0xF721,
    NSF31FunctionKey            = 0xF722,
    NSF32FunctionKey            = 0xF723,
    NSF33FunctionKey            = 0xF724,
    NSF34FunctionKey            = 0xF725,
    NSF35FunctionKey            = 0xF726,
    NSInsertFunctionKey         = 0xF727,
    NSDeleteFunctionKey         = 0xF728,
    NSHomeFunctionKey           = 0xF729,
    NSBeginFunctionKey          = 0xF72A,
    NSEndFunctionKey            = 0xF72B,
    NSPageUpFunctionKey         = 0xF72C,
    NSPageDownFunctionKey       = 0xF72D,
    NSPrintScreenFunctionKey    = 0xF72E,
    NSScrollLockFunctionKey     = 0xF72F,
    NSPauseFunctionKey          = 0xF730,
    NSSysReqFunctionKey         = 0xF731,
    NSBreakFunctionKey          = 0xF732,
    NSResetFunctionKey          = 0xF733,
    NSStopFunctionKey           = 0xF734,
    NSMenuFunctionKey           = 0xF735,
    NSUserFunctionKey           = 0xF736,
    NSSystemFunctionKey         = 0xF737,
    NSPrintFunctionKey          = 0xF738,
    NSClearLineFunctionKey      = 0xF739,
    NSClearDisplayFunctionKey   = 0xF73A,
    NSInsertLineFunctionKey     = 0xF73B,
    NSDeleteLineFunctionKey     = 0xF73C,
    NSInsertCharFunctionKey     = 0xF73D,
    NSDeleteCharFunctionKey     = 0xF73E,
    NSPrevFunctionKey           = 0xF73F,
    NSNextFunctionKey           = 0xF740,
    NSSelectFunctionKey         = 0xF741,
    NSExecuteFunctionKey        = 0xF742,
    NSUndoFunctionKey           = 0xF743,
    NSRedoFunctionKey           = 0xF744,
    NSFindFunctionKey           = 0xF745,
    NSHelpFunctionKey           = 0xF746,
    NSModeSwitchFunctionKey     = 0xF747
};

#else
#import <AppKit/AppKit.h>
#endif

@implementation CelestiaAppCore (AppKit)

// MARK: Mouse events
- (void)mouseButtonUp:(CGPoint)location modifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons {
    [self appCoreMouseButtonUp:location modifiers:[self toCelestiaModifiers:modifiers buttons:buttons]];
}

- (void)mouseButtonDown:(CGPoint)location modifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons {
    [self appCoreMouseButtonDown:location modifiers:[self toCelestiaModifiers:modifiers buttons:buttons]];
}

- (void)mouseDragged:(CGPoint)location {
    [self appCoreMouseDragged:location];
}

- (void)mouseMove:(CGPoint)offset modifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons {
    [self appCoreMouseMove:offset modifiers:[self toCelestiaModifiers:modifiers buttons:buttons]];
}

- (void)mouseWheel:(CGFloat)motion modifiers:(NSUInteger)modifiers {
    [self appCoreMouseWheel:motion modifiers:[self toCelestiaModifiers:modifiers buttons:0]];
}

// MARK: Private
- (int)toCelestiaModifiers:(NSUInteger)modifiers buttons:(CelestiaMouseButton)buttons {
    int cModifiers = 0;
    if (modifiers & NSEventModifierFlagCommand)
        cModifiers |= CelestiaCore::ControlKey;
    if (modifiers & NSEventModifierFlagControl)
        cModifiers |= CelestiaCore::ControlKey;
    if (modifiers & NSEventModifierFlagShift)
        cModifiers |= CelestiaCore::ShiftKey;
    if (buttons & CelestiaMouseButtonLeft)
        cModifiers |= CelestiaCore::LeftButton;
    if (buttons & CelestiaMouseButtonMiddle)
        cModifiers |= CelestiaCore::MiddleButton;
    if (buttons & CelestiaMouseButtonRight)
        cModifiers |= CelestiaCore::RightButton;
    if (modifiers & CelestiaEventModifierTouch)
        cModifiers |= CelestiaCore::Touch;
    return cModifiers;
}

// MARK: Key events
- (void)keyUp:(NSString *)input modifiers:(NSUInteger)modifiers {
    if (input == nil || input.length == 0) {
        return;
    }

    unichar key = [input characterAtIndex:0];
    int cModifiers = [self toCelestiaModifiers:modifiers buttons:0];
    [self appCoreKeyUp:[self toCelestiaKey:key modifiers:modifiers] modifiers:cModifiers];
}

- (void)keyDown:(NSString *)input modifiers:(NSUInteger)modifiers {
    if (input == nil || input.length == 0)
        return;

    unichar key = [input characterAtIndex:0];
    int cModifiers = [self toCelestiaModifiers:modifiers buttons:0];
    if ( key == NSDeleteCharacter )
        key = NSBackspaceCharacter; // delete = backspace
    else if ( key == NSDeleteFunctionKey || key == NSClearLineFunctionKey )
        key = NSDeleteCharacter; // del = delete
    else if ( key == NSBackTabCharacter )
        key = 127;

    if ((key < CelestiaCore::KeyCount) && ((key < '0') || (key >'9') || !(modifiers & NSEventModifierFlagNumericPad)))
        [self appCoreCharEnter:static_cast<char>(key) modifiers:cModifiers];

    [self appCoreKeyDown:[self toCelestiaKey:key modifiers:modifiers] modifiers:cModifiers];
}

- (void)keyUp:(NSInteger)input {
    [self appCoreKeyUp:static_cast<int>(input) modifiers:0];
}

- (void)keyDown:(NSInteger)input {
    [self appCoreKeyDown:static_cast<int>(input) modifiers:0];
}

- (void)charEnter:(char)input {
    [self appCoreCharEnter:input modifiers:0];
}

// MARK: Joystick events
- (void)joystickButtonUp:(CelestiaJoystickButton)button {
    [self appCoreJoystickButtonUp:static_cast<int>(button)];
}

- (void)joystickButtonDown:(CelestiaJoystickButton)button {
    [self appCoreJoystickButtonDown:static_cast<int>(button)];
}

- (void)joystickAxis:(CelestiaJoystickAxis)axis amount:(float)amount {
    [self appCoreJoystickAxis:axis amount:amount];
}

// MARK: Private
- (int)toCelestiaKey:(unichar)key modifiers:(NSUInteger)modifiers {

    int celestiaKey = 0;

    if ((modifiers & NSEventModifierFlagNumericPad) && (key >= '0') && (key <= '9'))
        switch(key)
    {
        case '0':
            celestiaKey = CelestiaCore::Key_NumPad0;
            break;
        case '1':
            celestiaKey = CelestiaCore::Key_NumPad1;
            break;
        case '2':
            celestiaKey = CelestiaCore::Key_NumPad2;
            break;
        case '3':
            celestiaKey = CelestiaCore::Key_NumPad3;
            break;
        case '4':
            celestiaKey = CelestiaCore::Key_NumPad4;
            break;
        case '5':
            celestiaKey = CelestiaCore::Key_NumPad5;
            break;
        case '6':
            celestiaKey = CelestiaCore::Key_NumPad6;
            break;
        case '7':
            celestiaKey = CelestiaCore::Key_NumPad7;
            break;
        case '8':
            celestiaKey = CelestiaCore::Key_NumPad8;
            break;
        case '9':
            celestiaKey = CelestiaCore::Key_NumPad9;
            break;
        default: break;
    }
    else switch(key)
    {
        case NSF1FunctionKey:
            celestiaKey = CelestiaCore::Key_F1;
            break;
        case NSF2FunctionKey:
            celestiaKey = CelestiaCore::Key_F2;
            break;
        case NSF3FunctionKey:
            celestiaKey = CelestiaCore::Key_F3;
            break;
        case NSF4FunctionKey:
            celestiaKey = CelestiaCore::Key_F4;
            break;
        case NSF5FunctionKey:
            celestiaKey = CelestiaCore::Key_F5;
            break;
        case NSF6FunctionKey:
            celestiaKey = CelestiaCore::Key_F6;
            break;
        case NSF7FunctionKey:
            celestiaKey = CelestiaCore::Key_F7;
            break;
        case NSF8FunctionKey:
            celestiaKey = CelestiaCore::Key_F8;
            break;
        case NSF9FunctionKey:
            celestiaKey = CelestiaCore::Key_F9;
            break;
        case NSF10FunctionKey:
            celestiaKey = CelestiaCore::Key_F10;
            break;
        case NSF11FunctionKey:
            celestiaKey = CelestiaCore::Key_F11;
            break;
        case NSF12FunctionKey:
            celestiaKey = CelestiaCore::Key_F12;
            break;
        case NSUpArrowFunctionKey:
            celestiaKey = CelestiaCore::Key_Up;
            break;
        case NSDownArrowFunctionKey:
            celestiaKey = CelestiaCore::Key_Down;
            break;
        case NSLeftArrowFunctionKey:
            celestiaKey = CelestiaCore::Key_Left;
            break;
        case NSRightArrowFunctionKey:
            celestiaKey = CelestiaCore::Key_Right;
            break;
        case NSPageUpFunctionKey:
            celestiaKey = CelestiaCore::Key_PageUp;
            break;
        case NSPageDownFunctionKey:
            celestiaKey = CelestiaCore::Key_PageDown;
            break;
        case NSHomeFunctionKey:
            celestiaKey = CelestiaCore::Key_Home;
            break;
        case NSEndFunctionKey:
            celestiaKey = CelestiaCore::Key_End;
            break;
        case NSInsertFunctionKey:
            celestiaKey = CelestiaCore::Key_Insert;
            break;
        default:
            if ((key < 128) && (key > 33))
            {
                celestiaKey = static_cast<int>(key & 0x00FF);
            }
            break;
    }

    return celestiaKey;
}

- (void)pinchUpdate:(CGPoint)focus scale:(CGFloat)scale zoomFOV:(BOOL)zoomFOV {
    core->pinchUpdate(static_cast<float>(focus.x), static_cast<float>(focus.y), static_cast<float>(scale), static_cast<bool>(zoomFOV));
}

- (void)pinchUpdate:(simd_float3)focus scale:(CGFloat)scale {
    core->pinchUpdate(Eigen::Vector3f(focus[0], focus[1], focus[2]), static_cast<float>(scale));
}

@end
