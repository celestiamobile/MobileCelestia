// CXCFont.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Font)
@interface CXCFont : NSObject

@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) NSInteger index;
@property (readonly, nonatomic) NSInteger size;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPath:(NSString *)path index:(NSInteger)index size:(NSInteger)size;

@end

NS_ASSUME_NONNULL_END
