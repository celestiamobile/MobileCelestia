// CelestiaAppCore+Setting.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <CelestiaCore/CelestiaAppCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CelestiaMeasurementSystem) {
    CelestiaMeasurementSystemMetric      = 0,
    CelestiaMeasurementSystemImperial    = 1,
} NS_SWIFT_NAME(MeasurementSystem);

typedef NS_ENUM(NSInteger, CelestiaTemperatureScale) {
    CelestiaTemperatureScaleKelvin       = 0,
    CelestiaTemperatureScaleCelsius      = 1,
    CelestiaTemperatureScaleFahrenheit   = 2,
} NS_SWIFT_NAME(TemperatureScale);

typedef NS_ENUM(NSInteger, CelestiaScriptSystemAccessPolicy) {
    CelestiaScriptSystemAccessPolicyAsk      = 0,
    CelestiaScriptSystemAccessPolicyAllow    = 1,
    CelestiaScriptSystemAccessPolicyDeny     = 2,
} NS_SWIFT_NAME(ScriptSystemAccessPolicy);

typedef NS_ENUM(NSInteger, CelestiaLayoutDirection) {
    CelestiaLayoutDirectionLTR      = 0,
    CelestiaLayoutDirectionRTL      = 1,
} NS_SWIFT_NAME(LayoutDirection);

@interface CelestiaAppCore (Setting)

// Time Settings

@property double time ;

@property NSInteger timeZone ;

@property double timeScale ;

@property BOOL synchTime;

// Gaze Settings

@property float fieldOfView ;

// situation

// Cruise Settings

// Velocity
// AngularVelocity

// Visibility Settings

@property BOOL showStars ;

@property BOOL showPlanets ;

@property BOOL showDwarfPlanets ;

@property BOOL showMoons ;

@property BOOL showMinorMoons ;

@property BOOL showAsteroids ;

@property BOOL showComets ;

@property BOOL showSpacecrafts ;

@property BOOL showOpenClusters ;

@property BOOL showGalaxies ;

@property BOOL showDiagrams ;

@property BOOL showCloudMaps ;

@property BOOL showOrbits ;

@property BOOL showFadingOrbits ;

@property BOOL showCelestialSphere ;

@property BOOL showNightMaps ;

@property BOOL showAtmospheres ;

@property BOOL showSmoothLines ;

@property BOOL showEclipseShadows ;

@property BOOL showRingShadows ;

@property BOOL showCloudShadows ;

@property BOOL showBoundaries ;

@property BOOL showAutoMag ;

@property BOOL showCometTails ;

@property BOOL showPlanetRings ;

@property BOOL showMarkers ;

@property BOOL showPartialTrajectories ;

@property BOOL showEcliptic ;

// Label Settings

// -(BOOL) showNoLabels ;
// -(void) setShowNoLabels: (BOOL) value ;

@property BOOL showStarLabels ;

@property BOOL showPlanetLabels ;

@property BOOL showMoonLabels ;

@property BOOL showConstellationLabels ;

@property BOOL showGalaxyLabels ;

@property BOOL showAsteroidLabels ;

@property BOOL showSpacecraftLabels ;

@property BOOL showLocationLabels ;

@property BOOL showCometLabels ;

// -(BOOL) showBodyLabels ;
// -(void) setShowBodyLabels: (BOOL) value ;

// Orbit Settings

@property BOOL showPlanetOrbits ;

@property BOOL showMoonOrbits ;

@property BOOL showAsteroidOrbits ;

@property BOOL showCometOrbits ;

@property BOOL showSpacecraftOrbits ;

@property BOOL showStellarOrbits ;

@property float minimumOrbitSize ;

// Location Visibility Settings

// Feature Settings

@property float minimumFeatureSize ;

// Reference Vectors

- (BOOL)referenceMarkEnabled:(NSString *)referenceMark forSelection:(CelestiaSelection *)selection NS_SWIFT_NAME(isReferenceMarkEnabled(_:for:));
- (void)toggleReferenceMark:(NSString *)referenceMark forSelection:(CelestiaSelection *)selection NS_SWIFT_NAME(toggleReferenceMark(_:for:));

// Lighting Settings

@property float ambientLightLevel ;

// Output Rendering Settings

@property NSInteger toneMapping;
@property float exposure;

// Star Settings

@property float distanceLimit ;

@property float faintestVisible ;

@property NSInteger starStyle ;

@property float starPointRadius;
@property float starOptimization;
@property float starMaxIrradiance;
@property float starDimClipFactor;
@property float starExposure;

@property NSInteger starColors ;
@property float tintSaturation;

// HUD Settings

@property NSInteger hudDetail;

// Texture Settings

@property NSInteger resolution;

// Atmosphere Quality Settings

@property NSInteger atmosphereSegmentCount;
@property NSInteger cloudSegmentCount;
@property BOOL separateRayleighMieScaleHeights;

@property CelestiaMeasurementSystem measurementSystem;
@property CelestiaTemperatureScale temperatureScale;
@property CelestiaScriptSystemAccessPolicy scriptSystemAccessPolicy;
@property CelestiaLayoutDirection layoutDirection;

@property BOOL enableReverseWheel;
@property BOOL enableRayBasedDragging;
@property BOOL enableFocusZooming;
@property BOOL enableAlignCameraToSurfaceOnLand;

@property BOOL mixedImmersion;

@property CelestiaOverlayElements overlayElements;

- (void)loadUserDefaults:(NSUserDefaults *)userDefaults withAppDefaultsAtPath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
