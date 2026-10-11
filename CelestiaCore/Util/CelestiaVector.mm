// CelestiaVector.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaVector+Private.h"

@interface CelestiaVector () {
    NSArray* _array;
}
@end

@implementation CelestiaVector (Private)

/*** Conversions to and from Eigen structures ***/

+(CelestiaVector*)vectorWithVector3f:(const Eigen::Vector3f&)v
{
    return [CelestiaVector vectorWithx:[NSNumber numberWithFloat:v.x()] y:[NSNumber numberWithFloat:v.y()] z:[NSNumber numberWithFloat:v.z()]];
}

+(CelestiaVector*)vectorWithVector3d:(const Eigen::Vector3d&)v
{
    return [CelestiaVector vectorWithx:[NSNumber numberWithDouble:v.x()] y:[NSNumber numberWithDouble:v.y()] z:[NSNumber numberWithDouble:v.z()]];
}

+(CelestiaVector*)vectorWithQuaternionf:(const Eigen::Quaternionf&)v
{
    return [CelestiaVector vectorWithx:[NSNumber numberWithFloat:v.x()] y:[NSNumber numberWithFloat:v.y()] z:[NSNumber numberWithFloat:v.z()] w:[NSNumber numberWithFloat:v.w()]];
}

+(CelestiaVector*)vectorWithQuaterniond:(const Eigen::Quaterniond&)v
{
    return [CelestiaVector vectorWithx:[NSNumber numberWithDouble:v.x()] y:[NSNumber numberWithDouble:v.y()] z:[NSNumber numberWithDouble:v.z()] w:[NSNumber numberWithDouble:v.w()]];
}

-(CelestiaVector*)initWithVector3f:(const Eigen::Vector3f&)v
{
    return [self initWithx:[NSNumber numberWithFloat:v.x()] y:[NSNumber numberWithFloat:v.y()] z:[NSNumber numberWithFloat:v.z()]];
}

-(CelestiaVector*)initWithVector3d:(const Eigen::Vector3d&)v
{
    return [self initWithx:[NSNumber numberWithDouble:v.x()] y:[NSNumber numberWithDouble:v.y()] z:[NSNumber numberWithDouble:v.z()]];
}

-(Eigen::Vector3f)vector3f
{
    return Eigen::Vector3f([[self x] floatValue],[[self y] floatValue],[[self z] floatValue]);
}

-(Eigen::Vector3d)vector3d
{
    return Eigen::Vector3d([[self x] doubleValue],[[self y] doubleValue],[[self z] doubleValue]);
}

-(Eigen::Quaternionf)quaternionf
{
    return Eigen::Quaternionf([[self w] floatValue],[[self x] floatValue],[[self y] floatValue],[[self z] floatValue]);
}

-(Eigen::Quaterniond)quaterniond
{
    return Eigen::Quaterniond([[self w] doubleValue],[[self x] doubleValue],[[self y] doubleValue],[[self z] doubleValue]);
}

/*** End Eigen conversions ***/
@end

@implementation CelestiaVector
-(void)encodeWithCoder:(NSCoder*)coder
{
    //[super encodeWithCoder:coder];
    [coder encodeObject:_array];
}
-(id)initWithCoder:(NSCoder*)coder
{
    //self = [super initWithCoder:coder];
    self = [self init];
    _array = [coder decodeObject];
    return self;
}
+(CelestiaVector*)vectorWithArray:(NSArray*)v
{
    return [[CelestiaVector alloc] initWithArray:v];
}
+(CelestiaVector*)vectorWithx:(NSNumber*)x y:(NSNumber*)y
{
    return [[CelestiaVector alloc] initWithx:x y:y];
}
+(CelestiaVector*)vectorWithx:(NSNumber*)x y:(NSNumber*)y z:(NSNumber*)z
{
    return [[CelestiaVector alloc] initWithx:x y:y z:z];
}
+(CelestiaVector*)vectorWithx:(NSNumber*)x y:(NSNumber*)y z:(NSNumber*)z w:(NSNumber*)w
{
    return [[CelestiaVector alloc] initWithx:x y:y z:z w:w];
}
-(CelestiaVector*)initWithArray:(NSArray*)v
{
    self = [super init];
    _array = v;
    return self;
}
-(CelestiaVector*)initWithx:(NSNumber*)x y:(NSNumber*)y
{
    self = [super init];
    _array = [[NSArray alloc] initWithObjects:x,y,nil];
    return self;
}
-(CelestiaVector*)initWithx:(NSNumber*)x y:(NSNumber*)y z:(NSNumber*)z
{
    self = [super init];
    _array = [[NSArray alloc] initWithObjects:x,y,z,nil];
    return self;
}
-(CelestiaVector*)initWithx:(NSNumber*)x y:(NSNumber*)y z:(NSNumber*)z w:(NSNumber*)w
{
    self = [super init];
    _array = [[NSArray alloc] initWithObjects:x,y,z,w,nil];
    return self;
}
-(NSNumber*)x
{
    return [_array objectAtIndex:0];
}
-(NSNumber*)y
{
    return [_array objectAtIndex:1];
}
-(NSNumber*)z
{
    return [_array objectAtIndex:2];
}
-(NSNumber*)w
{
    return [_array objectAtIndex:3];
}
-(NSNumber*)objectAtIndex:(NSUInteger)index
{
    return [_array objectAtIndex:index];
}
-(NSUInteger)count
{
    return [_array count];
}


- (double)dx {
    return [[self x] doubleValue];
}

- (double)dy {
    return [[self y] doubleValue];
}

- (double)dz {
    return [[self z] doubleValue];
}

- (double)dw {
    return [[self w] doubleValue];
}

@end
