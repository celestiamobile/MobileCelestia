//
// CEHExceptionCatching.m
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CEHExceptionCatching.h"

@implementation CEHExceptionCatching

+ (void)executeBlock:(dispatch_block_t)tryBlock exceptionHandler:(void (^)(NSException *))exceptionHandler {
    @try {
        tryBlock();
    } @catch (NSException *exception) {
        exceptionHandler(exception);
    }
}

@end
