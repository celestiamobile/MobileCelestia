// CelestiaUniverse+BrowserItem.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaUniverse+BrowserItem.h"
#import "CelestiaUniverse+Private.h"
#import "CelestiaStar+Private.h"
#import "CelestiaBody+Private.h"
#import "CelestiaLocation+Private.h"

#include <celutil/gettext.h>

@implementation CelestiaUniverse (BrowserItem)

- (NSDictionary *)childrenForBrowserItem:(CelestiaBrowserItem *)item {
    CelestiaAstroObject *entry = [item entry];
    if (entry == nil)
        return nil;

    if ([entry isKindOfClass:[CelestiaStar class]]) {
        CelestiaStar *star = (CelestiaStar *)entry;
        return [self childrenForStar:star];
    } else if ([entry isKindOfClass:[CelestiaBody class]]) {
        CelestiaBody *body = (CelestiaBody *)entry;
        return [self childrenForBody:body];
    }
    return nil;
}

- (NSDictionary *)childrenForStar:(CelestiaStar *)aStar {
    SolarSystem *ss = [self universe]->getSolarSystem([aStar star]);
    PlanetarySystem* sys = nullptr;
    if (ss) sys = ss->getPlanets();

    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];

    if (sys)
    {
        int sysSize = sys->getSystemSize();
        NSMutableDictionary *subItem = nil;
        NSMutableDictionary *planets = nil;
        NSMutableDictionary *dwarfPlanets = nil;
        NSMutableDictionary *minorMoons = nil;
        NSMutableDictionary *asteroids = nil;
        NSMutableDictionary *comets = nil;
        NSMutableDictionary *spacecrafts = nil;
        int i;
        for (i = 0; i < sysSize; i++)
        {
            Body* body = sys->getBody(i);
            if (body->getName().empty())
                continue;
            NSString *name = [NSString stringWithUTF8String:body->getName(true).c_str()];
            if (!name)
                continue;
            CelestiaBrowserItem *item = [[CelestiaBrowserItem alloc] initWithName:name catEntry:[[CelestiaBody alloc] initWithBody:body] provider:self];
            auto bodyClass  = body->getClassification();
            switch (bodyClass)
            {
                case BodyClassification::Invisible:
                case BodyClassification::Diffuse:
                case BodyClassification::Component:
                    continue;
                case BodyClassification::Planet:
                    if (!planets)
                        planets = [NSMutableDictionary dictionary];
                    subItem = planets;
                    break;
                case BodyClassification::DwarfPlanet:
                    if (!dwarfPlanets)
                        dwarfPlanets = [NSMutableDictionary dictionary];
                    subItem = dwarfPlanets;
                    break;
                case BodyClassification::Moon:
                case BodyClassification::MinorMoon:
                    if (body->getRadius() < 100.0f || BodyClassification::MinorMoon == bodyClass)
                    {
                        if (!minorMoons)
                            minorMoons = [NSMutableDictionary dictionary];
                        subItem = minorMoons;
                    }
                    else
                    {
                        subItem = resultDictionary;
                    }
                    break;
                case BodyClassification::Asteroid:
                    if (!asteroids)
                        asteroids = [NSMutableDictionary dictionary];
                    subItem = asteroids;
                    break;
                case BodyClassification::Comet:
                    if (!comets)
                        comets = [NSMutableDictionary dictionary];
                    subItem = comets;
                    break;
                case BodyClassification::Spacecraft:
                    if (!spacecrafts)
                        spacecrafts = [NSMutableDictionary dictionary];
                    subItem = spacecrafts;
                    break;
                default:
                    subItem = resultDictionary;
                    break;
            }
            [subItem setObject:item forKey:name];
        }

        if (planets) {
            NSString *name = [NSString stringWithUTF8String:_("Planets")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:planets] forKey:name];
        }
        if (dwarfPlanets) {
            NSString *name = [NSString stringWithUTF8String:_("Dwarf Planets")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:dwarfPlanets] forKey:name];
        }
        if (minorMoons) {
            NSString *name = [NSString stringWithUTF8String:_("Minor Moons")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:minorMoons] forKey:name];
        }
        if (asteroids) {
            NSString *name = [NSString stringWithUTF8String:_("Asteroids")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:asteroids] forKey:name];
        }
        if (comets) {
            NSString *name = [NSString stringWithUTF8String:_("Comets")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:comets] forKey:name];
        }
        if (spacecrafts) {
            NSString *name = [NSString stringWithUTF8String:_("Spacecraft")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:spacecrafts] forKey:name];
        }
    }
    return resultDictionary;
}

- (NSDictionary *)childrenForBody:(CelestiaBody *)aBody {
    PlanetarySystem* sys = [aBody body]->getSatellites();

    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];

    if (sys)
    {
        int sysSize = sys->getSystemSize();
        NSMutableDictionary *subItem = nil;
        NSMutableDictionary *minorMoons = nil;
        NSMutableDictionary *comets = nil;
        NSMutableDictionary *spacecrafts = nil;
        int i;
        for (i = 0; i < sysSize; i++)
        {
            Body* body = sys->getBody(i);
            if (body->getName().empty())
                continue;
            NSString *name = [NSString stringWithUTF8String:body->getName(true).c_str()];
            if (!name)
                continue;
            CelestiaBrowserItem *item = [[CelestiaBrowserItem alloc] initWithName:name catEntry:[[CelestiaBody alloc] initWithBody:body] provider:self];
            auto bodyClass  = body->getClassification();

            if (bodyClass == BodyClassification::Asteroid) bodyClass = BodyClassification::Moon;

            switch (bodyClass)
            {
                case BodyClassification::Invisible:
                case BodyClassification::Diffuse:
                case BodyClassification::Component:
                    continue;
                case BodyClassification::Moon:
                case BodyClassification::MinorMoon:
                    if (body->getRadius() < 100.0f || BodyClassification::MinorMoon == bodyClass)
                    {
                        if (!minorMoons)
                            minorMoons = [NSMutableDictionary dictionary];
                        subItem = minorMoons;
                    }
                    else
                    {
                        subItem = resultDictionary;
                    }
                    break;
                case BodyClassification::Comet:
                    if (!comets)
                        comets = [NSMutableDictionary dictionary];
                    subItem = comets;
                    break;
                case BodyClassification::Spacecraft:
                    if (!spacecrafts)
                        spacecrafts = [NSMutableDictionary dictionary];
                    subItem = spacecrafts;
                    break;
                default:
                    subItem = resultDictionary;
                    break;
            }
            [subItem setObject:item forKey:name];
        }

        if (minorMoons) {
            NSString *name = [NSString stringWithUTF8String:_("Minor Moons")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:minorMoons] forKey:name];
        }
        if (comets) {
            NSString *name = [NSString stringWithUTF8String:_("Comets")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:comets] forKey:name];
        }
        if (spacecrafts) {
            NSString *name = [NSString stringWithUTF8String:_("Spacecraft")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:spacecrafts] forKey:name];
        }
    }

    auto locations = GetBodyFeaturesManager()->getLocations([aBody body]);
    if (locations.has_value() && !locations->empty())
    {
        NSMutableDictionary *locationDictionary = [NSMutableDictionary dictionary];
        for (const auto loc : *locations)
        {
            NSString *name = [NSString stringWithUTF8String:loc->getName(true).c_str()];
            if (name == nil)
                continue;
            CelestiaLocation *location = [[CelestiaLocation alloc] initWithLocation:loc];
            [locationDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name catEntry:location provider:nil] forKey:name];
        }
        if ([locationDictionary count] > 0) {
            NSString *name = [NSString stringWithUTF8String:_("Locations")];
            [resultDictionary setObject:[[CelestiaBrowserItem alloc] initWithName:name children:locationDictionary] forKey:name];
        }
    }

    return resultDictionary;
}

@end
