//
// CelestiaFont.m
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CelestiaFont.h"
#include <ft2build.h>
#include FT_FREETYPE_H

@implementation CelestiaFont

+ (NSArray<NSString *> *)parseFontNames:(NSString *)path {
    static FT_Library ftlib = NULL;
    if (ftlib == NULL && FT_Init_FreeType(&ftlib) != 0)
        return nil;

    FT_Face face;

    // Get the number of faces by passing -1 as face_index
    if (FT_New_Face(ftlib, [path UTF8String], -1, &face) != 0)
        return nil;

    FT_Long faceNum = face->num_faces;
    FT_Done_Face(face);
    if (faceNum <= 0)
        return nil;

    NSMutableArray *fontNames = [NSMutableArray array];
    for (FT_Long i = 0; i < faceNum; ++i)
    {
        // If any of the faces fail, fail all
        if (FT_New_Face(ftlib, [path UTF8String], i, &face) != 0)
            return nil;

        NSString *familyName = face->family_name == NULL ? nil : [NSString stringWithUTF8String:face->family_name];
        NSString *styleName = face->style_name == NULL ? nil : [NSString stringWithUTF8String:face->style_name];

        if (familyName != nil)
        {
            NSString *name = familyName;
            if (styleName != nil)
            {
                name = [NSString stringWithFormat:@"%@ (%@)", familyName, styleName];
            }
            [fontNames addObject:name];
        }
        FT_Done_Face(face);
    }
    return [fontNames copy];
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
        NSArray *fontNames = [CelestiaFont parseFontNames:path];
        _fontNames = fontNames == nil ? [NSArray array] : fontNames;
    }
    return self;
}

@end
