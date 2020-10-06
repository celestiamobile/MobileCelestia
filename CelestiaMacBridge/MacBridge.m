//
// MacBridge.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "MacBridge.h"

@implementation MacBridge

+ (CGFloat)catalystScaleFactor {
    Class clazz = NSClassFromString(@"_UIiOSMacIdiomManager");
    if (clazz) {
        SEL selector = NSSelectorFromString(@"scaleFactor");
        if ([clazz respondsToSelector:selector]) {
            NSObject *result = [clazz valueForKey:NSStringFromSelector(selector)];
            if (result && [result isKindOfClass:[NSNumber class]]) {
                return [(NSNumber *)result floatValue];
            }
        }
    }
    return 1.0;
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

@end
