//
//  NSObject+Flag.m
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/26.
//  Copyright © 2020 李林峰. All rights reserved.
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
