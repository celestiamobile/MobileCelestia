//
// CXCFontCollection.m
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CXCFontCollection.h"

@implementation CXCFontCollection

- (instancetype)initWithMainFont:(CXCFont *)mainFont titleFont:(CXCFont *)titleFont normalRenderFont:(CXCFont *)normalRenderFont largeRenderFont:(CXCFont *)largeRenderFont {
    self = [super init];
    if (self) {
        _mainFont = mainFont;
        _titleFont = titleFont;
        _normalRenderFont = normalRenderFont;
        _largeRenderFont = largeRenderFont;
    }
    return self;
}

@end
