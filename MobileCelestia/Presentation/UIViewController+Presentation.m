//
// UIViewController+Presentation.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "UIViewController+Presentation.h"

#import <objc/runtime.h>

@interface WeakObjectContainer : NSObject
@property (nonatomic, readonly, weak) id object;
@end

@implementation WeakObjectContainer

- (instancetype)initWithObject:(id)object
{
    if (!(self = [super init]))
        return nil;

    _object = object;

    return self;
}

@end

@implementation UIViewController (Presentation)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(dismissViewControllerAnimated:completion:);
        SEL swizzledSelector = @selector(cel_dismissViewControllerAnimated:completion:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
            class_addMethod(class,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


- (id<UIViewControllerDismissDelegate>)dismissDelegate {
    return [objc_getAssociatedObject(self, @selector(dismissDelegate)) object];
}

- (void)setDismissDelegate:(id<UIViewControllerDismissDelegate>)dismissDelegate {
    objc_setAssociatedObject(self, @selector(dismissDelegate), [[WeakObjectContainer alloc] initWithObject:dismissDelegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cel_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    UIViewController *target = [self presentedViewController];
    if (!target) {
        target = self;
    }
    id delegate = [target dismissDelegate];
    if ([delegate respondsToSelector:@selector(viewControllerWillDismiss:)]) {
        [delegate viewControllerWillDismiss:target];
    }
    [self cel_dismissViewControllerAnimated:flag completion:completion];
    delegate = [target dismissDelegate];
    if ([delegate respondsToSelector:@selector(viewControllerDidDismiss:)]) {
        [delegate viewControllerDidDismiss:target];
    }
}

@end
