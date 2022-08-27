//
// CELMacBridge.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CELMacBridge.h"

@implementation CELMacBridge

+ (CGFloat)catalystScaleFactor {
    Class clazz = NSClassFromString(@"_UIiOSMacIdiomManager");
    if (clazz) {
        // macOS 10.15
        SEL selector = NSSelectorFromString(@"scaleFactor");
        if ([clazz respondsToSelector:selector]) {
            NSObject *result = [clazz valueForKey:NSStringFromSelector(selector)];
            if (result && [result isKindOfClass:[NSNumber class]]) {
                return [(NSNumber *)result floatValue];
            }
        } else {
            // macOS 11.0
            selector = NSSelectorFromString(@"sceneScaleFactor");
            if ([clazz respondsToSelector:selector]) {
                NSObject *result = [clazz valueForKey:NSStringFromSelector(selector)];
                if (result && [result isKindOfClass:[NSNumber class]]) {
                    return [(NSNumber *)result floatValue];
                }
            }
        }
    }
    return 1.0;
}

+ (CGPoint)currentMouseLocation {
    CGEventRef event = CGEventCreate(NULL);
    CGPoint point = CGEventGetLocation(event);
    CFRelease(event);
    return point;
}

+ (void)forceDarkAppearance {
    [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
}

+ (id)nsWindowForUIWindow:(id)uiWindow {
    // https://gist.github.com/steipete/30c33740bf0ebc34a0da897cba52fefe
    id delegate = [[NSApplication sharedApplication] delegate];
    const SEL hostWinSEL = NSSelectorFromString(@"_hostWindowForUIWindow:");
    @try {
        // There's also hostWindowForUIWindow 🤷‍♂️
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id nsWindow = [delegate performSelector:hostWinSEL withObject:uiWindow];
#pragma clang diagnostic pop

        // macOS 11.0 changed this to return an UINSWindowProxy
        SEL attachedWin = NSSelectorFromString(@"attachedWindow");
        if ([nsWindow respondsToSelector:attachedWin])
            nsWindow = [nsWindow valueForKey:NSStringFromSelector(attachedWin)];

        return nsWindow;
    } @catch (...) {
        NSLog(@"Failed to get NSWindow for %@.", uiWindow);
    }
    return nil;
}

+ (void)disableFullScreenForNSWindow:(NSWindow *)window {
    NSWindowCollectionBehavior behavior = NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorFullScreenNone;
    [window setCollectionBehavior:behavior];
    NSButton *button = [window standardWindowButton:NSWindowZoomButton];
    [button setEnabled:NO];
}

+ (void)disableTabbingForAllWindows {
    [NSWindow setAllowsAutomaticWindowTabbing:NO];
}

+ (void)showTextInputSheetForWindow:(NSWindow *)window title:(NSString *)title message:(nullable NSString *)message text:(nullable NSString *)text placeholder:(nullable NSString *)placeholder okButtonTitle:(NSString *)okButtonTitle cancelButtonTitle:(NSString *)cancelButtonTitle completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    const CGFloat alertTextInputWidth = 228;
    const CGFloat alertTextInputDefaultHeight = 21;
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message == nil ? @"" : message;
    [alert addButtonWithTitle:okButtonTitle];
    [alert addButtonWithTitle:cancelButtonTitle];
    NSTextField *textField = [NSTextField new];
    CGFloat height = [textField fittingSize].height < 1 ? alertTextInputDefaultHeight : [textField fittingSize].height;
    [textField setFrame:NSMakeRect(0, 0, alertTextInputWidth, height)];
    [textField setStringValue:text == nil ? @"" : text];
    [textField setPlaceholderString:placeholder];
    alert.accessoryView = textField;
    [alert layout];
    [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            completionHandler(textField.stringValue);
        } else {
            completionHandler(nil);
        }
    }];
}

@end
