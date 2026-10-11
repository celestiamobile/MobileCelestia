// CelestiaUtil.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaVector;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DMS)
@interface CelestiaDMS : NSObject

@property (readonly) NSInteger hmsHours;
@property (readonly) NSInteger hmsMinutes;
@property (readonly) double hmsSeconds;

@property (readonly) NSInteger degrees;
@property (readonly) NSInteger minutes;
@property (readonly) double seconds;

@property (readonly) double decimal;

- (instancetype)initWithDecimal:(double)decimal;
- (instancetype)initWithDegrees:(NSInteger)degrees minutes:(NSInteger)minutes seconds:(double)seconds;

@end

@interface NSDate (Astro)

@property (readonly) double julianDay;

+ (instancetype)dateWithJulian:(double)jd;

@end

NS_SWIFT_NAME(AstroUtils)
@interface CelestiaAstroUtils : NSObject

+ (double)speedOfLight;
+ (double)J2000;
+ (double)G;
+ (double)solarMass;
+ (double)earthMass;
+ (float)lumToAbsMag:(float)lum;
+ (float)lumToAppMag:(float)lum lightYears:(float)lyrs;
+ (float)absMagToLum:(float)mag;
+ (float)absToAppMag:(float)mag lightYears:(float)lyrs;
+ (float)appToAbsMag:(float)mag lightYears:(float)lyrs;
+ (double)lightYearsToParsecs:(double)ly;
+ (double)parsecsToLightYears:(double)pc;
+ (double)lightYearsToKilometers:(double)ly;
+ (double)kilometersToLightYears:(double)km;
+ (double)lightYearsToAU:(double)ly;
+ (double)AUtoLightYears:(double)au;
+ (double)kilometersToAU:(double)km;
+ (double)AUtoKilometers:(double)au;
+ (double)microLightYearsToKilometers:(double)mly;
+ (double)kilometersToMicroLightYears:(double)km;
+ (double)microLightYearsToAU:(double)mly;
+ (double)AUtoMicroLightYears:(double)au;
+ (double)secondsToJulianDate:(double)sec;
+ (double)julianDateToSeconds:(double)jd;
+ (NSArray<NSNumber *> *)anomaly:(double)meanAnamaly eccentricity:(double)eccentricity;
+ (double)meanEclipticObliquity:(double)jd;
+ (CelestiaVector *)celToJ2000Ecliptic:(CelestiaVector *)cel;
+ (CelestiaVector *)eclipticToEquatorial:(CelestiaVector *)ecliptic;
+ (CelestiaVector *)equatorialToGalactic:(CelestiaVector *)equatorial;
+ (CelestiaVector *)rectToSpherical:(CelestiaVector *)rect;
+ (double)degFromRad:(double)rad;

@end

NS_ASSUME_NONNULL_END
