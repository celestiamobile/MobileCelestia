//
// CEHExceptionCatching.h
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ExceptionCatching)
@interface CEHExceptionCatching : NSObject

+ (void)executeBlock:(dispatch_block_t)tryBlock exceptionHandler:(void (^)(NSException *))exceptionHandler;

@end

NS_ASSUME_NONNULL_END
