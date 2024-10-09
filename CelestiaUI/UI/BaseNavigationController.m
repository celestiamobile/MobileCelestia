//
// BaseNavigationController.m
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "BaseNavigationController.h"

@interface NavigationControllerDelegateProxy : NSObject <UINavigationControllerDelegate>

@property (nonatomic, weak) id<UINavigationControllerDelegate> originalDelegate;
@property (nonatomic, weak) id<UINavigationControllerDelegate> wrappedDelegate;

- (instancetype)initWithOriginalDelegate:(id<UINavigationControllerDelegate>)originalDelegate wrappedDelegate:(id<UINavigationControllerDelegate>)wrappedDelegate;

@end

@implementation NavigationControllerDelegateProxy

- (instancetype)initWithOriginalDelegate:(id<UINavigationControllerDelegate>)originalDelegate wrappedDelegate:(id<UINavigationControllerDelegate>)wrappedDelegate {
    self = [super init];
    if (self) {
        self.originalDelegate = originalDelegate;
        self.wrappedDelegate = wrappedDelegate;
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.wrappedDelegate respondsToSelector:aSelector] || [self.originalDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.wrappedDelegate respondsToSelector:aSelector]) {
        return self.wrappedDelegate;
    } else if ([self.originalDelegate respondsToSelector:aSelector]) {
        return self.originalDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

@end

@interface BaseNavigationController () <UINavigationControllerDelegate>

@property (nonatomic, strong) NavigationControllerDelegateProxy *delegateProxy;

@end

@implementation BaseNavigationController

- (id<UINavigationControllerDelegate>)delegate {
    return [super delegate];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    self.delegateProxy = [[NavigationControllerDelegateProxy alloc] initWithOriginalDelegate:delegate wrappedDelegate:self];
    [super setDelegate:self.delegateProxy];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.delegate = nil;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.delegate = nil;
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.delegate = nil;
    }
    return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass {
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        self.delegate = nil;
    }
    return self;
}

- (void)topViewControllerDidChange:(UIViewController *)viewController {}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self topViewControllerDidChange:viewController];
    id<UINavigationControllerDelegate> actualDelegate = self.delegateProxy.originalDelegate;
    if ([actualDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [actualDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
}

@end
