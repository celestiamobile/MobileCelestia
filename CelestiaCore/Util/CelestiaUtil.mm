// CelestiaUtil.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#include <cmath>
#include <numbers>

#include <celastro/date.h>
#include <celengine/observer.h>

#import "CelestiaUtil.h"
#import "CelestiaVector+Private.h"

@implementation CelestiaDMS

- (instancetype)initWithDecimal:(double)decimal {
    self = [super init];
    if (self)
        _decimal = decimal;
    return self;
}

- (instancetype)initWithDegrees:(NSInteger)degrees minutes:(NSInteger)minutes seconds:(double)seconds {
    self = [super init];
    if (self)
        _decimal = celestia::astro::degMinSecToDecimal(static_cast<int>(degrees), static_cast<int>(minutes), static_cast<double>(seconds));
    return self;
}

- (NSInteger)degrees {
    int degrees;
    int minutes;
    double seconds;
    celestia::astro::decimalToDegMinSec(_decimal, degrees, minutes, seconds);
    return static_cast<NSInteger>(degrees);
}

- (NSInteger)minutes {
    int degrees;
    int minutes;
    double seconds;
    celestia::astro::decimalToDegMinSec(_decimal, degrees, minutes, seconds);
    return static_cast<NSInteger>(minutes);
}

- (double)seconds {
    int degrees;
    int minutes;
    double seconds;
    celestia::astro::decimalToDegMinSec(_decimal, degrees, minutes, seconds);
    return seconds;
}

- (NSInteger)hmsHours {
    int hours;
    int minutes;
    double seconds;
    celestia::astro::decimalToHourMinSec(_decimal, hours, minutes, seconds);
    return static_cast<NSInteger>(hours);
}

- (NSInteger)hmsMinutes {
    int hours;
    int minutes;
    double seconds;
    celestia::astro::decimalToHourMinSec(_decimal, hours, minutes, seconds);
    return static_cast<NSInteger>(minutes);
}

- (double)hmsSeconds {
    int hours;
    int minutes;
    double seconds;
    celestia::astro::decimalToHourMinSec(_decimal, hours, minutes, seconds);
    return seconds;
}

@end

@implementation NSDate (Astro)

- (double)julianDay {
    static auto epoch = celestia::astro::Date(1970, 1, 1);
    return celestia::astro::UTCtoTDB(epoch + [self timeIntervalSince1970] / 86400.0);
}

+ (instancetype)dateWithJulian:(double)jd {
    static auto epoch = celestia::astro::Date(1970, 1, 1);
    auto date = (celestia::astro::TDBtoUTC(jd) - epoch) * 86400.0;
    return [[NSDate alloc] initWithTimeIntervalSince1970:date];
}

@end

@implementation CelestiaAstroUtils

+ (double)speedOfLight {
    return celestia::astro::speedOfLight;
}

+ (double)J2000 {
    return celestia::astro::J2000;
}

+ (double)G {
    return celestia::astro::G;
}

+ (double)solarMass {
    return celestia::astro::SolarMass;
}

+ (double)earthMass {
    return celestia::astro::EarthMass;
}

+ (float)lumToAbsMag:(float)lum {
    return celestia::astro::lumToAbsMag(lum);
}

+ (float)lumToAppMag:(float)lum lightYears:(float)lyrs {
    return celestia::astro::lumToAppMag(lum, lyrs);
}

+ (float)absMagToLum:(float)mag {
    return celestia::astro::absMagToLum(mag);
}

+ (float)absToAppMag:(float)mag lightYears:(float)lyrs {
    return celestia::astro::absToAppMag(mag, lyrs);
}
+ (float)appToAbsMag:(float)mag lightYears:(float)lyrs {
    return celestia::astro::appToAbsMag(mag, lyrs);
}

+ (double)lightYearsToParsecs:(double)ly {
    return celestia::astro::lightYearsToParsecs(ly);
}

+ (double)parsecsToLightYears:(double)pc {
    return celestia::astro::parsecsToLightYears(pc);
}

+ (double)lightYearsToKilometers:(double)ly {
    return celestia::astro::lightYearsToKilometers(ly);
}

+ (double)kilometersToLightYears:(double)km {
    return celestia::astro::kilometersToLightYears(km);
}

+ (double)lightYearsToAU:(double)ly {
    return celestia::astro::lightYearsToAU(ly);
}

+ (double)AUtoLightYears:(double)au {
    return celestia::astro::AUtoLightYears(au);
}

+ (double)kilometersToAU:(double)km {
    return celestia::astro::kilometersToAU(km);
}

+ (double)AUtoKilometers:(double)au {
    return celestia::astro::AUtoKilometers(au);
}

+ (double)microLightYearsToKilometers:(double)mly {
    return celestia::astro::microLightYearsToKilometers(mly);
}

+ (double)kilometersToMicroLightYears:(double)km {
    return celestia::astro::kilometersToMicroLightYears(km);
}

+ (double)microLightYearsToAU:(double)mly {
    return celestia::astro::microLightYearsToAU(mly);
}

+ (double)AUtoMicroLightYears:(double)au {
    return celestia::astro::AUtoMicroLightYears(au);
}

+ (double)secondsToJulianDate:(double)sec {
    return celestia::astro::secondsToJulianDate(sec);
}

+ (double)julianDateToSeconds:(double)jd {
    return celestia::astro::julianDateToSeconds(jd);
}

+ (NSArray<NSNumber *> *)anomaly:(double)meanAnamaly eccentricity:(double)eccentricity {
    double trueAnomaly,eccentricAnomaly;
    celestia::astro::anomaly(meanAnamaly, eccentricity, trueAnomaly, eccentricAnomaly);
    return [NSArray arrayWithObjects:[NSNumber numberWithDouble:trueAnomaly], [NSNumber numberWithDouble:eccentricAnomaly], nil];
}

+ (double)meanEclipticObliquity:(double)jd {
    return celestia::astro::meanEclipticObliquity(jd);
}

+ (CelestiaVector *)celToJ2000Ecliptic:(CelestiaVector *)cel {
    Eigen::Vector3d p = [cel vector3d];
    return [CelestiaVector vectorWithVector3d:Eigen::Vector3d(p.x(), -p.z(), p.y())];
}

+ (CelestiaVector *)eclipticToEquatorial:(CelestiaVector *)ecliptic {
    return [CelestiaVector vectorWithVector3d:celestia::astro::eclipticToEquatorial([ecliptic vector3d])];
}

+ (CelestiaVector *)equatorialToGalactic:(CelestiaVector *)equatorial {
    return [CelestiaVector vectorWithVector3d:celestia::astro::equatorialToGalactic([equatorial vector3d])];
}

+ (CelestiaVector *)rectToSpherical:(CelestiaVector *)rect {
    Eigen::Vector3d v = [rect vector3d];
    double r = v.norm();
    double theta = std::atan2(v.y(), v.x());
    if (theta < 0)
        theta = theta + 2 * std::numbers::pi;
    double phi = asin(v.z() / r);

    return [CelestiaVector vectorWithVector3d:Eigen::Vector3d(theta, phi, r)];
}

+ (double)degFromRad:(double)rad {
    return celestia::math::radToDeg(rad);
}

@end
