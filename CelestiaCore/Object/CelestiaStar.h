// CelestiaStar.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <CelestiaCore/CelestiaAstroObject.h>

NS_ASSUME_NONNULL_BEGIN

@class CelestiaUniversalCoord;

NS_SWIFT_NAME(Star)
@interface CelestiaStar : CelestiaAstroObject

@property (readonly) float radius;
@property (readonly) float temperature;

@property (readonly) NSString *spectralType;
@property (readonly) float absoluteMagnitude;

- (void)setAbsoluteMagnitude:(float)m;
- (float)apparentMagnitude:(float)m;

- (CelestiaUniversalCoord *)positionAtTime:(NSDate *)time NS_SWIFT_NAME(position(at:));

@end

NS_ASSUME_NONNULL_END
