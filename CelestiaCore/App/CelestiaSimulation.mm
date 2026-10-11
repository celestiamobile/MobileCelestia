// CelestiaSimulation.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#include <numbers>

#import "CelestiaSimulation+Private.h"
#import "CelestiaCompletion+Private.h"
#import "CelestiaSelection+Private.h"
#import "CelestiaUniverse+Private.h"
#import "CelestiaObserver+Private.h"
#import "CelestiaUniversalCoord+Private.h"
#import "CelestiaVector+Private.h"
#import "CelestiaUtil.h"
#import "CelestiaPlanetarySystem.h"
#import "CelestiaEclipseFinder.h"
#import "CelestiaBody.h"
#import "CelestiaBody+Private.h"
#import "CelestiaStar.h"
#import "CelestiaDestination.h"

#include "celmath/geomutil.h"
#include "celmath/intersect.h"
#include "celmath/sphere.h"

using namespace celestia::math;

namespace
{

Eigen::Vector3d findMaxEclipsePoint(const Eigen::Vector3d& toOcculter,
                                    const Eigen::Vector3d& toReceiver,
                                    double receiverRadius)
{
    double distance = 0.0;
    if (testIntersection(Eigen::ParametrizedLine<double, 3>(Eigen::Vector3d::Zero(), toOcculter),
                         Sphered(toReceiver, receiverRadius),
                         distance))
    {
        return toOcculter * distance - toReceiver;
    }

    const double t = toReceiver.dot(toOcculter) / toOcculter.squaredNorm();
    Eigen::Vector3d point = t * toOcculter - toReceiver;
    return point * (receiverRadius / point.norm());
}

}

typedef NS_OPTIONS(NSUInteger, CelestiaGoToLocationFieldMask) {
    CelestiaGoToLocationFieldMaskLongitude = 1 << 0,
    CelestiaGoToLocationFieldMaskLatitude = 1 << 1,
    CelestiaGoToLocationFieldMaskDistance = 1 << 2,
};

@implementation CelestiaGoToLocation {
@public
    CelestiaGoToLocationFieldMask fieldMask;
    double _duration;
}

- (instancetype)initWithSelection:(CelestiaSelection *)selection longitude:(float)longitude latitude:(float)latitude distance:(double)distance unit:(CelestiaSimulationDistanceUnit)unit validMask:(CelestiaGoToLocationFieldMask)mask {
    self = [super init];
    if (self) {
        fieldMask = mask;
        _selection = selection;
        _longitude = longitude;
        _latitude = latitude;
        // 5 seconds as a default of travel duration
        _duration = 5;

        switch (unit) {
            case CelestiaSimulationDistanceUnitKM:
                _distance = distance;
                break;
            case CelestiaSimulationDistanceUnitAU:
                _distance = [CelestiaAstroUtils AUtoKilometers:distance];
                break;
            case CelestiaSimulationDistanceUnitRadii:
            default:
                _distance = [selection radius] * distance;
                break;
        }
    }
    return self;
}

- (instancetype)initWithSelection:(CelestiaSelection *)selection longitude:(float)longitude latitude:(float)latitude distance:(double)distance unit:(CelestiaSimulationDistanceUnit)unit {
    return [self initWithSelection:selection longitude:longitude latitude:latitude distance:distance unit:unit validMask:CelestiaGoToLocationFieldMaskLongitude | CelestiaGoToLocationFieldMaskLatitude | CelestiaGoToLocationFieldMaskDistance];
}

- (instancetype)initWithSelection:(CelestiaSelection *)selection longitude:(float)longitude latitude:(float)latitude {
    return [self initWithSelection:selection longitude:longitude latitude:latitude distance:0 unit:CelestiaSimulationDistanceUnitKM validMask:CelestiaGoToLocationFieldMaskLongitude | CelestiaGoToLocationFieldMaskLatitude];
}

- (instancetype)initWithSelection:(CelestiaSelection *)selection distance:(double)distance unit:(CelestiaSimulationDistanceUnit)unit {
    return [self initWithSelection:selection longitude:0 latitude:0 distance:distance unit:unit validMask:CelestiaGoToLocationFieldMaskDistance];
}

- (instancetype)initWithSelection:(CelestiaSelection *)selection {
    return [self initWithSelection:selection longitude:0 latitude:0 distance:0 unit:CelestiaSimulationDistanceUnitKM validMask:0];
}

- (void)setDuration:(double)duration {
    _duration = MAX(0, duration);
}

- (double)duration {
    return _duration;
}

@end

@interface CelestiaSimulation () {
    Simulation *s;

    CelestiaUniverse *_universe;
}

@end

@implementation CelestiaSimulation (Private)

- (instancetype)initWithSimulation:(Simulation *)sim {
    self = [super init];
    if (self) {
        s = sim;

        _universe = nil;
    }
    return self;
}

- (Simulation *)simulation {
    return s;
}

@end

@implementation CelestiaSimulation

- (CelestiaSelection *)selection {
    return [[CelestiaSelection alloc] initWithSelection:s->getSelection()];
}

- (void)setSelection:(CelestiaSelection *)selection {
    s->setSelection([selection selection]);
}

- (NSDate *)time {
    return [NSDate dateWithJulian:s->getTime()];
}

- (void)setTime:(NSDate *)time {
    s->setTime([time julianDay]);
}

- (double)julianDay {
    return s->getTime();
}

- (void)setJulianDay:(double)julianDay {
    s->setTime(julianDay);
}

- (CelestiaObserver *)activeObserver {
    return [[CelestiaObserver alloc] initWithObserver:s->getActiveObserver()];
}

- (CelestiaGoToLocation *)currentLocation {
    CelestiaSelection *sel = [self selection];
    if ([sel isEmpty]) {
        return nil;
    }
    double distance, longitude, latitude;
    s->getSelectionLongLat(distance, longitude, latitude);
    return [[CelestiaGoToLocation alloc] initWithSelection:sel longitude:longitude latitude:latitude distance:distance unit:CelestiaSimulationDistanceUnitKM];
}

- (CelestiaUniverse *)universe {
    if (!_universe) {
        _universe = [[CelestiaUniverse alloc] initWithUniverse:s->getUniverse()];
    }
    return _universe;
}

- (CelestiaSelection *)findObjectFromPath:(NSString *)path {
    return [[CelestiaSelection alloc] initWithSelection:[self simulation]->findObjectFromPath([path UTF8String], true)];
}

- (void)reverseObserverOrientation {
    s->reverseObserverOrientation();
}

- (void)update:(NSTimeInterval)seconds {
    s->update(seconds);
}

- (void)goToLocation:(CelestiaGoToLocation *)location {
    [self setSelection:location.selection];
    [self simulation]->geosynchronousFollow();
    double distance = location.selection.radius * 5.0;
    if (location->fieldMask & CelestiaGoToLocationFieldMaskDistance) {
        distance = location.distance;
    }

    CelestiaVector *up = [CelestiaVector vectorWithx:[NSNumber numberWithFloat:0.0f] y:[NSNumber numberWithFloat:1.0f] z:[NSNumber numberWithFloat:0.0f]];
    if (location->fieldMask & CelestiaGoToLocationFieldMaskLongitude && location->fieldMask & CelestiaGoToLocationFieldMaskLatitude) {
        s->gotoSelectionLongLat(location.duration, distance, location.longitude * std::numbers::pi_v<float> / 180.0f, location.latitude * std::numbers::pi_v<float> / 180.0f, [up vector3f]);
    } else {
        s->gotoSelection(location.duration, distance, [up vector3f], ObserverFrame::CoordinateSystem::ObserverLocal);
    }
}

- (void)performEclipseAction:(CelestiaEclipseAction)action eclipse:(CelestiaEclipse *)eclipse {
    Body *receiver = [[eclipse receiver] body];
    Body *occulter = [[eclipse occulter] body];
    Star *sun = receiver->getSystem()->getStar();
    if (!sun)
        return;

    const double midEclipseTime = (eclipse.startTime.julianDay + eclipse.endTime.julianDay) / 2.0;
    if (action == CelestiaEclipseActionSetTime) {
        s->setTime(midEclipseTime);
        return;
    }

    double now = s->getTime();
    if (now < eclipse.startTime.julianDay || now > eclipse.endTime.julianDay)
        s->setTime(midEclipseTime);
    now = s->getTime();

    const Eigen::Vector3d toOcculter = occulter->getPosition(now).offsetFromKm(sun->getPosition(now));
    const Eigen::Vector3d toReceiver = receiver->getPosition(now).offsetFromKm(sun->getPosition(now));
    const Eigen::Vector3d receiverUp = receiver->getEclipticToBodyFixed(now).conjugate() * Eigen::Vector3d::UnitY();

    Body *frameBody = receiver;
    Eigen::Vector3d position;
    Eigen::Quaterniond orientation;

    switch (action) {
    case CelestiaEclipseActionNearEclipsedBody: {
        const Eigen::Vector3d eclipsePoint = findMaxEclipsePoint(toOcculter, toReceiver, receiver->getRadius());
        position = eclipsePoint * 4.0;
        orientation = LookAt<double>(position, eclipsePoint, receiverUp);
        break;
    }
    case CelestiaEclipseActionFromEclipsedBodySurface: {
        const Eigen::Vector3d eclipsePoint = findMaxEclipsePoint(toOcculter, toReceiver, receiver->getRadius());
        position = eclipsePoint * 1.0001;
        orientation = LookAt<double>(eclipsePoint, -toReceiver, eclipsePoint.normalized());
        break;
    }
    case CelestiaEclipseActionFromOcculterSurface:
    case CelestiaEclipseActionBehindOcculter:
        frameBody = occulter;
        position = toOcculter.normalized() * occulter->getRadius()
            * (action == CelestiaEclipseActionFromOcculterSurface ? 1.0001 : 20.0);
        orientation = LookAt<double>(position, toReceiver, receiverUp);
        break;
    case CelestiaEclipseActionSetTime:
        return;
    }

    s->setFrame(ObserverFrame::CoordinateSystem::Ecliptical, frameBody);
    s->gotoLocation(UniversalCoord::Zero().offsetKm(position), orientation, 5.0);
}

- (void)goToDestination:(CelestiaDestination *)destination {
    Selection sel = s->findObjectFromPath([[destination target] UTF8String]);
    if (!sel.empty())
    {
        s->follow();
        s->setSelection(sel);
        if ([destination distance] <= 0)
        {
            // Use the default distance
            s->gotoSelection(5.0,
                             Eigen::Vector3f::UnitY(),
                             ObserverFrame::CoordinateSystem::ObserverLocal);
        }
        else
        {
            s->gotoSelection(5.0,
                             [destination distance],
                             Eigen::Vector3f::UnitY(),
                             ObserverFrame::CoordinateSystem::ObserverLocal);
        }
    }
}

- (NSArray<CelestiaCompletion *> *)completionForName:(NSString *)name {
    std::vector<celestia::engine::Completion> completions;
    s->getObjectCompletion(completions, [name UTF8String], true);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:completions.size()];
    for (auto const& completion : completions) {
        CelestiaCompletion *result = [[CelestiaCompletion alloc] initWithCompletion:completion];
        [array addObject:result];
    }
    return array;
}

- (simd_quatf)observerQuaternion {
    Eigen::Quaternionf q = s->getActiveObserver()->getOrientationTransform().cast<float>();
    return simd_quaternion(q.x(), q.y(), q.z(), q.w());
}

- (void)setObserverQuaternion:(simd_quatf)cameraQuaternion {
    Eigen::Quaterniond q(cameraQuaternion.vector[3], cameraQuaternion.vector[0], cameraQuaternion.vector[1], cameraQuaternion.vector[2]);
    s->getActiveObserver()->setOrientationTransform(q);
}

@end
