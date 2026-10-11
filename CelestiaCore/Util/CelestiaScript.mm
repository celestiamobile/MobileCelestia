// CelestiaScript.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaScript.h"
#import "celestia/scriptmenu.h"

@implementation CelestiaScript

- (instancetype)initWithItem:(ScriptMenuItem)item {
    self = [super init];
    if (self) {
        _filename = [NSString stringWithUTF8String:item.filename.c_str()];
        _title = [NSString stringWithUTF8String:item.title.c_str()];
    }
    return self;
}

+ (NSArray *)scriptsInDirectory:(NSString *)directory deepScan:(BOOL)deep {
    auto results = ScanScriptsDirectory([directory UTF8String], deep ? true : false);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:results.size()];

    for (const auto & result : results)
        [array addObject:[[CelestiaScript alloc] initWithItem:result]];

    return array;
}

@end
