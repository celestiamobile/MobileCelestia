//
// CXCFont.m
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CXCFont.h"

@implementation CXCFont

- (instancetype)initWithPath:(NSString *)path index:(NSInteger)index size:(NSInteger)size {
    self = [super init];
    if (self) {
        _path = path;
        _index = index;
        _size = size;
    }
    return self;
}

@end
