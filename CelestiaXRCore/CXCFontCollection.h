// CXCFontCollection.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CXCFont;

NS_SWIFT_NAME(FontCollection)
@interface CXCFontCollection : NSObject

@property (readonly, nonatomic) CXCFont *mainFont;
@property (readonly, nonatomic) CXCFont *titleFont;
@property (readonly, nonatomic) CXCFont *normalRenderFont;
@property (readonly, nonatomic) CXCFont *largeRenderFont;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMainFont:(CXCFont *)mainFont titleFont:(CXCFont *)titleFont normalRenderFont:(CXCFont *)normalRenderFont largeRenderFont:(CXCFont *)largeRenderFont;

@end

NS_ASSUME_NONNULL_END
