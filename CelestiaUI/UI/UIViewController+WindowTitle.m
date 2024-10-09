//
// UIViewController+WindowTitle.m
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import <objc/runtime.h>

#import "UIViewController+WindowTitle.h"

@implementation UIViewController (WindowTitle)

- (NSString *)windowTitle {
    return objc_getAssociatedObject(self, @selector(windowTitle));
}

- (void)setWindowTitle:(NSString *)windowTitle {
    [self willChangeValueForKey:@"windowTitle"];
    objc_setAssociatedObject(self, @selector(windowTitle), windowTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self didChangeValueForKey:@"windowTitle"];
}

@end
