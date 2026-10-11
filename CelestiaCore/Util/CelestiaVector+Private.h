// CelestiaVector+Private.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaVector.h"
#include <Eigen/Core>
#include <Eigen/Geometry>

@interface CelestiaVector (Private)

+ (CelestiaVector*)vectorWithVector3f:(const Eigen::Vector3f&)v;
+ (CelestiaVector*)vectorWithVector3d:(const Eigen::Vector3d&)v;
+ (CelestiaVector*)vectorWithQuaternionf:(const Eigen::Quaternionf&)v;
+ (CelestiaVector*)vectorWithQuaterniond:(const Eigen::Quaterniond&)v;
- (CelestiaVector*)initWithVector3f:(const Eigen::Vector3f&)v;
- (CelestiaVector*)initWithVector3d:(const Eigen::Vector3d&)v;
- (Eigen::Vector3f)vector3f;
- (Eigen::Vector3d)vector3d;
- (Eigen::Quaternionf)quaternionf;
- (Eigen::Quaterniond)quaterniond;

@end
