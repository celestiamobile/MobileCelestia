// CelestiaDSO.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaDSO+Private.h"
#import "CelestiaAstroObject+Private.h"
#import "CelestiaVector+Private.h"
#import "CelestiaUtil.h"

@implementation CelestiaDSO (Private)

- (instancetype)initWithDSO:(DeepSkyObject *)aDSO {
    self = [super initWithObject:aDSO];
    return self;
}

- (DeepSkyObject *)DSO {
    return reinterpret_cast<DeepSkyObject *>([self object]);
}

@end

@implementation CelestiaDSO

- (NSString *)type {
    return [NSString stringWithUTF8String:[self DSO]->getType()];
}

- (CelestiaDSOType)objectType {
    return static_cast<CelestiaDSOType>([self DSO]->getObjType());
}

- (NSString *)dsoDescription {
    return [NSString stringWithUTF8String:[self DSO]->getDescription().c_str()];
}

- (CelestiaVector *)position {
    return [CelestiaVector vectorWithVector3d:[self DSO]->getPosition()];
}

@end
