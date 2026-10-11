// CelestiaAppCore+Setting.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#include <celengine/body.h>
#include <celengine/location.h>
#include <celutil/flag.h>

#import "CelestiaAppCore+Private.h"
#import "CelestiaAppCore+Setting.h"
#import "CelestiaAppCore+Locale.h"
#import "CelestiaSelection+Private.h"
#import "CelestiaBody.h"
#import "CelestiaUtil.h"

@implementation CelestiaAppCore (Setting)

- (id)valueForUndefinedKey:(NSString *)key {
#ifdef DEBUG
    if ( key ) NSLog(@"unbound value for %@", key);
#endif
    return nil;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
#ifdef DEBUG
    NSLog(@"unbound key set for %@", key);
#endif
}

- (void)setNilValueForKey:(NSString *)key {
#ifdef DEBUG
    NSLog(@"nil value for %@", key);
#endif
}

// Time Settings

- (double)time { return core->getSimulation()->getTime(); }
- (void)setTime:(double)value { core->getSimulation()->setTime(value); }

- (double)timeScale { return core->getSimulation()->getTimeScale(); }
- (void)setTimeScale:(double)value { core->getSimulation()->setTimeScale(value); }

- (BOOL)synchTime { return core->getSimulation()->getSyncTime(); }
- (void)setSynchTime:(BOOL)value { core->getSimulation()->setSyncTime(value); }

// Gaze Settings

- (float)fieldOfView { return core->getSimulation()->getObserver().getFOV(); }
- (void)setFieldOfView: (float)value { core->getSimulation()->getObserver().setFOV(value); }

// Observer Settings

// Cruise Settings

// Velocity
// AngularVelocity

- (uint64_t)setValue:(BOOL)value forBit:(uint64_t)bit inSet:(uint64_t)set {
    NSInteger result = value
    ? ((bit&set) ? set : (set|bit) )
    : ((bit&set) ?  (set^bit) : set);
    //    NSLog([NSString stringWithFormat: @"setValue %d forBit: %d inSet: %d = %d",value,bit,set,result]);
    //    NSLog([NSString stringWithFormat: @"bit was: %d bit is: %d ",(set&bit),(result&bit)]);
    return result;
}

// Visibility Settings

#define RENDERMETHODS(flag)  -(BOOL) show##flag { return static_cast<BOOL>(celestia::util::is_set(core->getRenderer()->getRenderFlags(), RenderFlags::Show##flag)); } -(void) setShow##flag: (BOOL) value  { auto flags = core->getRenderer()->getRenderFlags(); celestia::util::set_or_unset(flags, RenderFlags::Show##flag, static_cast<bool>(value)); core->getRenderer()->setRenderFlags(flags); }

RENDERMETHODS(Stars)
RENDERMETHODS(Planets)
RENDERMETHODS(DwarfPlanets)
RENDERMETHODS(Moons)
RENDERMETHODS(MinorMoons)
RENDERMETHODS(Asteroids)
RENDERMETHODS(Comets)
RENDERMETHODS(Spacecrafts)
RENDERMETHODS(Galaxies)
RENDERMETHODS(Globulars)
RENDERMETHODS(Nebulae)
RENDERMETHODS(OpenClusters)
RENDERMETHODS(Diagrams)
RENDERMETHODS(Boundaries)
RENDERMETHODS(CloudMaps)
RENDERMETHODS(NightMaps)
RENDERMETHODS(Atmospheres)
RENDERMETHODS(CometTails)
RENDERMETHODS(PlanetRings)
RENDERMETHODS(Markers)
RENDERMETHODS(Orbits)
RENDERMETHODS(FadingOrbits)
RENDERMETHODS(PartialTrajectories)
RENDERMETHODS(Ecliptic)
RENDERMETHODS(SmoothLines)
RENDERMETHODS(EclipseShadows)
RENDERMETHODS(RingShadows)
RENDERMETHODS(CloudShadows)
RENDERMETHODS(AutoMag)
RENDERMETHODS(CelestialSphere)
RENDERMETHODS(EclipticGrid)
RENDERMETHODS(HorizonGrid)
RENDERMETHODS(GalacticGrid)

// Label Settings

#define LABELMETHODS(flag)  -(BOOL) show##flag##Labels { return static_cast<BOOL>(celestia::util::is_set(core->getRenderer()->getLabelMode(), RenderLabels::flag##Labels)); } -(void) setShow##flag##Labels : (BOOL) value  { auto flags = core->getRenderer()->getLabelMode(); celestia::util::set_or_unset(flags, RenderLabels::flag##Labels, static_cast<bool>(value)); core->getRenderer()->setLabelMode(flags); }

LABELMETHODS(Star)
LABELMETHODS(Planet)
LABELMETHODS(Moon)
LABELMETHODS(Constellation)
LABELMETHODS(Galaxy)
LABELMETHODS(Globular)
LABELMETHODS(Nebula)
LABELMETHODS(OpenCluster)
LABELMETHODS(Asteroid)
LABELMETHODS(Spacecraft)
LABELMETHODS(Location)
LABELMETHODS(Comet)
LABELMETHODS(DwarfPlanet)
LABELMETHODS(MinorMoon)

LABELMETHODS(I18nConstellation)

- (BOOL)showLatinConstellationLabels {
    return ![self showI18nConstellationLabels];
}
- (void)setShowLatinConstellationLabels:(BOOL)value {
    [self setShowI18nConstellationLabels:!value];
}

// Orbit Settings

#define ORBITMETHODS(flag)  -(BOOL) show##flag##Orbits { return static_cast<BOOL>(celestia::util::is_set(core->getRenderer()->getOrbitMask(), BodyClassification::flag)); } -(void) setShow##flag##Orbits: (BOOL) value  { auto flags = core->getRenderer()->getOrbitMask(); celestia::util::set_or_unset(flags, BodyClassification::flag, static_cast<bool>(value)); core->getRenderer()->setOrbitMask(flags); }

ORBITMETHODS(Planet)
ORBITMETHODS(Moon)
ORBITMETHODS(Asteroid)
ORBITMETHODS(Spacecraft)
ORBITMETHODS(Comet)
ORBITMETHODS(Stellar)
ORBITMETHODS(DwarfPlanet)
ORBITMETHODS(MinorMoon)


- (float)minimumOrbitSize { return core->getRenderer()->getMinimumOrbitSize(); }
- (void)setMinimumOrbitSize:(float)value { core->getRenderer()->setMinimumOrbitSize(value); }

// Feature Settings

#define FEATUREMETHODS(flag)  -(BOOL) show##flag##Labels { return (core->getSimulation()->getObserver().getLocationFilter()&Location::flag) != 0; } -(void) setShow##flag##Labels: (BOOL) value  { core->getSimulation()->getObserver().setLocationFilter([self setValue: value forBit: Location::flag inSet: core->getSimulation()->getObserver().getLocationFilter()]); }

FEATUREMETHODS(City)
FEATUREMETHODS(Observatory)
FEATUREMETHODS(LandingSite)
FEATUREMETHODS(Crater)
FEATUREMETHODS(Vallis)
FEATUREMETHODS(Mons)
FEATUREMETHODS(Planum)
FEATUREMETHODS(Chasma)
FEATUREMETHODS(Patera)
FEATUREMETHODS(Mare)
FEATUREMETHODS(Rupes)
FEATUREMETHODS(Tessera)
FEATUREMETHODS(Regio)
FEATUREMETHODS(Chaos)
FEATUREMETHODS(Terra)
FEATUREMETHODS(Astrum)
FEATUREMETHODS(Corona)
FEATUREMETHODS(Dorsum)
FEATUREMETHODS(Fossa)
FEATUREMETHODS(Catena)
FEATUREMETHODS(Mensa)
FEATUREMETHODS(Rima)
FEATUREMETHODS(Undae)
FEATUREMETHODS(Tholus)
FEATUREMETHODS(Reticulum)
FEATUREMETHODS(Planitia)
FEATUREMETHODS(Linea)
FEATUREMETHODS(Fluctus)
FEATUREMETHODS(Farrum)
FEATUREMETHODS(EruptiveCenter)
FEATUREMETHODS(Insula)
FEATUREMETHODS(Albedo)
FEATUREMETHODS(Arcus)
FEATUREMETHODS(Cavus)
FEATUREMETHODS(Colles)
FEATUREMETHODS(Facula)
FEATUREMETHODS(Flexus)
FEATUREMETHODS(Flumen)
FEATUREMETHODS(Fretum)
FEATUREMETHODS(Labes)
FEATUREMETHODS(Labyrinthus)
FEATUREMETHODS(Lacuna)
FEATUREMETHODS(Lacus)
FEATUREMETHODS(LargeRinged)
FEATUREMETHODS(Lobus)
FEATUREMETHODS(Lingula)
FEATUREMETHODS(Macula)
FEATUREMETHODS(Oceanus)
FEATUREMETHODS(Palus)
FEATUREMETHODS(Plume)
FEATUREMETHODS(Promontorium)
FEATUREMETHODS(Satellite)
FEATUREMETHODS(Scopulus)
FEATUREMETHODS(Serpens)
FEATUREMETHODS(Sinus)
FEATUREMETHODS(Sulcus)
FEATUREMETHODS(Vastitas)
FEATUREMETHODS(Virga)
FEATUREMETHODS(Saxum)
FEATUREMETHODS(Collum)
FEATUREMETHODS(Cosmodrome)
FEATUREMETHODS(Ring)
FEATUREMETHODS(Other)

- (float)minimumFeatureSize { return core->getRenderer()->getMinimumFeatureSize(); }
- (void)setMinimumFeatureSize:(float)value { core->getRenderer()->setMinimumFeatureSize(value); }

// Refmark Settings

- (BOOL)showBodyAxes {
    return core->referenceMarkEnabled("body axes");
}

- (void)setShowBodyAxes:(BOOL)value {
    core->toggleReferenceMark("body axes");
}

- (BOOL)showFrameAxes {
    return core->referenceMarkEnabled("frame axes");
}

- (void)setShowFrameAxes:(BOOL)value {
    core->toggleReferenceMark("frame axes");
}

- (BOOL)showSunDirection {
    return core->referenceMarkEnabled("sun direction");
}

- (void)setShowSunDirection:(BOOL)value {
    core->toggleReferenceMark("sun direction");
}

- (BOOL)showVelocityVector {
    return core->referenceMarkEnabled("velocity vector");
}

- (void)setShowVelocityVector:(BOOL)value {
    core->toggleReferenceMark("velocity vector");
}

- (BOOL)showPlanetographicGrid {
    return core->referenceMarkEnabled("planetographic grid");
}

- (void)setShowPlanetographicGrid:(BOOL)value {
    core->toggleReferenceMark("planetographic grid");
}

- (BOOL)showTerminator {
    return core->referenceMarkEnabled("terminator");
}

- (void)setShowTerminator:(BOOL)value {
    core->toggleReferenceMark("terminator");
}

- (BOOL)referenceMarkEnabled:(NSString *)referenceMark forSelection:(CelestiaSelection *)selection {
    return core->referenceMarkEnabled(referenceMark.UTF8String, selection.selection);
}

- (void)toggleReferenceMark:(NSString *)referenceMark forSelection:(CelestiaSelection *)selection {
    core->toggleReferenceMark(referenceMark.UTF8String, selection.selection);
}


// Lighting Settings

- (float)ambientLightLevel { return core->getRenderer()->getAmbientLightLevel(); }
- (void)setAmbientLightLevel:(float)value { core->getRenderer()->setAmbientLightLevel(value); }

- (NSInteger)toneMapping { return static_cast<NSInteger>(core->getRenderer()->getToneMappingMode()); }
- (void)setToneMapping:(NSInteger)value { core->getRenderer()->setToneMappingMode(static_cast<ToneMappingMode>(value)); }

- (float)exposure { return core->getRenderer()->getToneMappingExposure(); }
- (void)setExposure:(float)value { core->getRenderer()->setToneMappingExposure(value); }

- (float)galaxyBrightness { return Galaxy::getLightGain(); }
- (void)setGalaxyBrightness:(float)value { Galaxy::setLightGain(value); }

// Star Settings

- (float)distanceLimit { return core->getRenderer()->getDistanceLimit(); }
- (void)setDistanceLimit:(float)value { core->getRenderer()->setDistanceLimit(value); }

- (float)faintestVisible {
    //    return core->getSimulation()->getFaintestVisible();
    if (!celestia::util::is_set(core->getRenderer()->getRenderFlags(), RenderFlags::ShowAutoMag))
    {
        return core->getSimulation()->getFaintestVisible();
    }
    else
    {
        return core->getRenderer()->getFaintestAM45deg();
    }
}

- (void)setFaintestVisible:(float)value {
    if (!celestia::util::is_set(core->getRenderer()->getRenderFlags(), RenderFlags::ShowAutoMag))
    {
        core->setFaintest(value);
    }
    else
    {
        core->getRenderer()->setFaintestAM45deg(value);
        core->setFaintestAutoMag();
    }
}

- (NSInteger)starStyle { return static_cast<NSInteger>(core->getRenderer()->getStarStyle()); }
- (void)setStarStyle:(NSInteger)value { core->getRenderer()->setStarStyle(static_cast<StarStyle>(value)); }

- (float)starPointRadius { return core->getRenderer()->getStarPointRadius(); }
- (void)setStarPointRadius:(float)value { core->getRenderer()->setStarPointRadius(value); }

- (float)starOptimization { return core->getRenderer()->getStarOptimization(); }
- (void)setStarOptimization:(float)value { core->getRenderer()->setStarOptimization(value); }

- (float)starMaxIrradiance { return core->getRenderer()->getStarMaxIrradiance(); }
- (void)setStarMaxIrradiance:(float)value { core->getRenderer()->setStarMaxIrradiance(value); }

- (float)starDimClipFactor { return core->getRenderer()->getStarDimClipFactor(); }
- (void)setStarDimClipFactor:(float)value { core->getRenderer()->setStarDimClipFactor(value); }

- (float)starExposure { return core->getRenderer()->getStarExposure(); }
- (void)setStarExposure:(float)value { core->getRenderer()->setStarExposure(value); }

- (NSInteger)starColors {
    return static_cast<NSInteger>(core->getRenderer()->getStarColorTable());
}

- (void)setStarColors:(NSInteger)starColors {
    core->getRenderer()->setStarColorTable(static_cast<ColorTableType>(starColors));
}

- (float)tintSaturation {
    return core->getRenderer()->getTintSaturation();
}

- (void)setTintSaturation:(float)tintSaturation {
    core->getRenderer()->setTintSaturation(tintSaturation);
}

// Texture Settings

- (NSInteger)resolution { return static_cast<NSInteger>(core->getRenderer()->getResolution()); }
- (void)setResolution:(NSInteger)value { core->getRenderer()->setResolution(static_cast<celestia::engine::TextureResolution>(value)); }

// Atmosphere Quality Settings

- (NSInteger)atmosphereSegmentCount { return static_cast<NSInteger>(core->getRenderer()->getAtmosphereSegmentCount()); }
- (void)setAtmosphereSegmentCount:(NSInteger)value { core->getRenderer()->setAtmosphereSegmentCount(static_cast<unsigned int>(value)); }

- (NSInteger)cloudSegmentCount { return static_cast<NSInteger>(core->getRenderer()->getCloudSegmentCount()); }
- (void)setCloudSegmentCount:(NSInteger)value { core->getRenderer()->setCloudSegmentCount(static_cast<unsigned int>(value)); }

- (BOOL)separateRayleighMieScaleHeights { return static_cast<BOOL>(core->getRenderer()->getSeparateRayleighMieScaleHeights()); }
- (void)setSeparateRayleighMieScaleHeights:(BOOL)value { core->getRenderer()->setSeparateRayleighMieScaleHeights(static_cast<bool>(value)); }

// Overlay Settings

- (NSInteger)hudDetail { return core->getHudDetail(); }
- (void)setHudDetail:(NSInteger)value { core->setHudDetail((int)value); }

// Measurement Settings

- (CelestiaMeasurementSystem)measurementSystem { return (CelestiaMeasurementSystem)core->getMeasurementSystem(); }
- (void)setMeasurementSystem:(CelestiaMeasurementSystem)measurementSystem { return core->setMeasurementSystem((celestia::MeasurementSystem)measurementSystem); }

- (CelestiaTemperatureScale)temperatureScale { return (CelestiaTemperatureScale)core->getTemperatureScale(); }
- (void)setTemperatureScale:(CelestiaTemperatureScale)temperatureScale { return core->setTemperatureScale((celestia::TemperatureScale)temperatureScale); }

- (CelestiaScriptSystemAccessPolicy)scriptSystemAccessPolicy { return (CelestiaScriptSystemAccessPolicy)core->getScriptSystemAccessPolicy(); }
- (void)setScriptSystemAccessPolicy:(CelestiaScriptSystemAccessPolicy)scriptSystemAccessPolicy { return core->setScriptSystemAccessPolicy((CelestiaCore::ScriptSystemAccessPolicy)scriptSystemAccessPolicy); }

- (CelestiaLayoutDirection)layoutDirection { return static_cast<CelestiaLayoutDirection>(core->getLayoutDirection()); }
- (void)setLayoutDirection:(CelestiaLayoutDirection)layoutDirection { core->setLayoutDirection(static_cast<celestia::LayoutDirection>(layoutDirection)); }

#define INTERACTIONMETHODS(flag)  -(BOOL) enable##flag { return static_cast<BOOL>(celestia::util::is_set(core->getInteractionFlags(), CelestiaCore::InteractionFlags::flag)); } -(void) setEnable##flag: (BOOL) value  { auto flags = core->getInteractionFlags();celestia::util::set_or_unset(flags, CelestiaCore::InteractionFlags::flag, static_cast<bool>(value));core->setInteractionFlags(flags); }

INTERACTIONMETHODS(ReverseWheel);
INTERACTIONMETHODS(RayBasedDragging);
INTERACTIONMETHODS(FocusZooming);

#define OBSERVERMETHODS(flag)  -(BOOL) enable##flag { return static_cast<BOOL>(celestia::util::is_set(core->getObserverFlags(), celestia::engine::ObserverFlags::flag)); } -(void) setEnable##flag: (BOOL) value  { auto flags = core->getObserverFlags();celestia::util::set_or_unset(flags, celestia::engine::ObserverFlags::flag, static_cast<bool>(value));core->setObserverFlags(flags); }

OBSERVERMETHODS(AlignCameraToSurfaceOnLand);

- (CelestiaOverlayElements)overlayElements {
    return static_cast<CelestiaOverlayElements>(core->getOverlayElements());
}

- (void)setOverlayElements:(CelestiaOverlayElements)overlayElements {
    core->setOverlayElements(static_cast<celestia::HudElements>(overlayElements));
}

// Time settings

// Timezone values are inverted to maintain backward compatibility
- (NSInteger)timeZone { return core->getTimeZoneBias() == 0 ? 1 : 0; }

- (void)setTimeZone:(NSInteger)value {
    core->setTimeZoneBias(0 == value ? 1 : 0);
}

- (NSInteger)dateFormat { return core->getDateFormat(); }

- (void)setDateFormat:(NSInteger)value {
    core->setDateFormat(static_cast<celestia::astro::Date::Format>(value));
}

- (void)loadUserDefaults:(NSUserDefaults *)userDefaults withAppDefaultsAtPath:(nullable NSString *)path {
    NSDictionary* settingsDictionary = [self settingsWithUserDefaults:userDefaults appDefaultsAtPath:path];
    [settingsDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self setValue:obj forKey:key];
    }];
}

- (NSDictionary *)settingsWithUserDefaults:(NSUserDefaults *)userDefaults appDefaultsAtPath:(NSString *)path {
    if (path == nil) return [NSDictionary dictionary];

    NSString *oldDefaultsKey = @"Celestia-1.4.0";
    NSDictionary *appDefs = [[[NSDictionary alloc] initWithContentsOfFile:path] objectForKey:oldDefaultsKey];
    if (appDefs == nil) return [NSDictionary dictionary];

    NSDictionary *oldUserDefs = [userDefaults objectForKey:oldDefaultsKey];

    NSMutableDictionary *settingsDictionary = [NSMutableDictionary dictionary];

    [appDefs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id customValue = [oldUserDefs objectForKey:key];
        if (customValue != nil)
            [userDefaults setObject:customValue forKey:key]; // Migration
        else
            customValue = [userDefaults objectForKey:key];

        if (customValue != nil)
            [settingsDictionary setObject:customValue forKey:key];
        else
            [settingsDictionary setObject:obj forKey:key];
    }];

    // Remove the old user defaults
    if (oldUserDefs != nil)
        [userDefaults setObject:nil forKey:oldDefaultsKey];

    return [settingsDictionary copy];
}

@end
