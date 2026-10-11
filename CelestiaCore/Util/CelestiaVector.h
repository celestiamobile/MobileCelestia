// CelestiaVector.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Vector)
@interface CelestiaVector : NSArray

@property (readonly) NSNumber *x;
@property (readonly) NSNumber *y;
@property (readonly) NSNumber *z;
@property (readonly) NSNumber *w;

@property (readonly) double dx;
@property (readonly) double dy;
@property (readonly) double dz;
@property (readonly) double dw;

- (void)encodeWithCoder:(NSCoder*)coder;
- (id)initWithCoder:(NSCoder*)coder;
+ (CelestiaVector*)vectorWithArray:(NSArray*)v;
+ (CelestiaVector*)vectorWithx:(NSNumber*)v y:(NSNumber*)y;
+ (CelestiaVector*)vectorWithx:(NSNumber*)v y:(NSNumber*)y z:(NSNumber*)z;
+ (CelestiaVector*)vectorWithx:(NSNumber*)v y:(NSNumber*)y z:(NSNumber*)z w:(NSNumber*)w;
- (CelestiaVector*)initWithArray:(NSArray*)v;
- (CelestiaVector*)initWithx:(NSNumber*)v y:(NSNumber*)y;
- (CelestiaVector*)initWithx:(NSNumber*)v y:(NSNumber*)y z:(NSNumber*)z;
- (CelestiaVector*)initWithx:(NSNumber*)v y:(NSNumber*)y z:(NSNumber*)z w:(NSNumber*)w;
- (NSUInteger)count;
- (NSNumber*)objectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
