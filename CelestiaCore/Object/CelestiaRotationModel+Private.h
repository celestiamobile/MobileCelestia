// CelestiaRotationModel+Private.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaRotationModel.h"
#include "celephem/rotation.h"

NS_ASSUME_NONNULL_BEGIN

@interface CelestiaRotationModel (Private)

- (instancetype)initWithRotation:(const celestia::ephem::RotationModel *)rotation;
- (const celestia::ephem::RotationModel *)rotation;

@end

NS_ASSUME_NONNULL_END
