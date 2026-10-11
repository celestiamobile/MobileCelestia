// CelestiaGalaxy.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaGalaxy.h"
#import "CelestiaAstroObject+Private.h"
#import "CelestiaGalaxy+Private.h"

@implementation CelestiaGalaxy (Private)

- (instancetype)initWithGalaxy:(Galaxy *)galaxy
{
    self = [super initWithObject:galaxy];
    return self;
}

-(Galaxy *)galaxy {
    return reinterpret_cast<Galaxy *>([self object]);
}

@end

/*
    GalacticForm* getForm() const;
*/

@implementation CelestiaGalaxy

-(NSString *)type {
    return [NSString stringWithUTF8String:[self galaxy]->getType()];
}

-(NSString *)name {
    return @"";
}

- (float)radius {
    return [self galaxy]->getRadius();
}

- (void)setRadius:(float)r {
    [self galaxy]->setRadius(r);
}

- (float)detail {
    return [self galaxy]->getDetail();
}

- (void)setDetail:(float)d {
    [self galaxy]->setDetail(d);
}

@end
