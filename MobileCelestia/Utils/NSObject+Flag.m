//
// NSObject+Flag.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "NSObject+Flag.h"

#import <objc/runtime.h>

@implementation NSObject (Presentation)

- (NSInteger)customFlag {
    return [objc_getAssociatedObject(self, @selector(customFlag)) integerValue];
}

- (void)setCustomFlag:(NSInteger)customFlag {
    objc_setAssociatedObject(self, @selector(customFlag), [NSNumber numberWithInteger:customFlag], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
