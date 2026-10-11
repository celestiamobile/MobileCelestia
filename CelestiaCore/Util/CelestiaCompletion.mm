// CelestiaCompletion.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaCompletion+Private.h"
#import "CelestiaSelection+Private.h"

#include <memory>

@interface CelestiaCompletion () {
    std::unique_ptr<celestia::engine::Completion> c;
}
@end

@implementation CelestiaCompletion (Private)

- (instancetype)initWithCompletion:(const celestia::engine::Completion&)completion {
    self = [super init];
    if (self) {
        c = std::make_unique<celestia::engine::Completion>(completion);
    }
    return self;
}

@end

@implementation CelestiaCompletion

- (NSString *)name {
    return [NSString stringWithUTF8String:c->getName().c_str()];
}

- (CelestiaSelection *)selection {
    return [[CelestiaSelection alloc] initWithSelection:c->getSelection()];
}

@end
