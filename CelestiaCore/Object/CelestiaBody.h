// CelestiaBody.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <CelestiaCore/CelestiaAstroObject.h>

@class CelestiaOrbit;
@class CelestiaPlanetarySystem;
@class CelestiaRotationModel;
@class CelestiaStarCatalog;
@class CelestiaTimeline;

typedef NS_ENUM(NSUInteger, CelestiaBodyType) {
    CelestiaBodyTypePlanet         =    0x01,
    CelestiaBodyTypeMoon           =    0x02,
    CelestiaBodyTypeAsteroid       =    0x04,
    CelestiaBodyTypeComet          =    0x08,
    CelestiaBodyTypeSpacecraft     =    0x10,
    CelestiaBodyTypeInvisible      =    0x20,
    CelestiaBodyTypeBarycenter     =    0x40, // Not used (invisible is used instead)
    CelestiaBodyTypeSmallBody      =    0x80, // Not used
    CelestiaBodyTypeDwarfPlanet    =   0x100,
    CelestiaBodyTypeStellar        =   0x200, // only used for orbit mask
    CelestiaBodyTypeSurfaceFeature =   0x400,
    CelestiaBodyTypeComponent      =   0x800,
    CelestiaBodyTypeMinorMoon      =  0x1000,
    CelestiaBodyTypeDiffuse        =  0x2000,
    CelestiaBodyTypeUnknown        = 0x10000,
} NS_SWIFT_NAME(BodyType);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Body)
@interface CelestiaBody : CelestiaAstroObject

@property (nonatomic, readonly) CelestiaBodyType type;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) float radius;
@property (nonatomic, readonly, getter=isEllipsoid) BOOL ellipsoid;
@property (nonatomic, readonly) BOOL hasRings;
@property (nonatomic, readonly) BOOL hasAtmosphere;
@property (nonatomic) float mass;
@property (nonatomic) float geomAlbedo;
@property (nonatomic, readonly) NSArray<NSString *> *alternateSurfaceNames;

@property (nonatomic, nullable, readonly) CelestiaPlanetarySystem *system;

@property (nonatomic, readonly) CelestiaTimeline *timeline;

@property (nonatomic, readonly) BOOL canBeUsedAsCockpit;

- (CelestiaOrbit *)orbitAtTime:(NSDate *)time NS_SWIFT_NAME(orbit(at:));
- (CelestiaRotationModel *)rotationAtTime:(NSDate *)time NS_SWIFT_NAME(rotation(at:));
- (NSString *)pathWithCatalog:(CelestiaStarCatalog *)starCatalog NS_SWIFT_NAME(path(with:));

@end

NS_ASSUME_NONNULL_END
