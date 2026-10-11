// CelestiaCore.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <Foundation/Foundation.h>

//! Project version number for CelestiaCore.
FOUNDATION_EXPORT double CelestiaCoreVersionNumber;

//! Project version string for CelestiaCore.
FOUNDATION_EXPORT const unsigned char CelestiaCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CelestiaCore/PublicHeader.h>

#import <CelestiaCore/CelestiaAppCore.h>
#import <CelestiaCore/CelestiaAppCore+Setting.h>
#import <CelestiaCore/CelestiaAppCore+Event.h>
#import <CelestiaCore/CelestiaAppCore+Locale.h>
#import <CelestiaCore/CelestiaAppCore+Render.h>
#import <CelestiaCore/CelestiaAppState.h>
#import <CelestiaCore/CelestiaSimulation.h>
#import <CelestiaCore/CelestiaUniverse.h>
#import <CelestiaCore/CelestiaObserver.h>

#import <CelestiaCore/CelestiaUtil.h>
#import <CelestiaCore/CelestiaBrowserItem.h>
#import <CelestiaCore/CelestiaScript.h>
#import <CelestiaCore/CelestiaVector.h>
#import <CelestiaCore/CelestiaUniversalCoord.h>
#import <CelestiaCore/CelestiaUniverse+BrowserItem.h>

#import <CelestiaCore/CelestiaSelection.h>
#import <CelestiaCore/CelestiaCompletion.h>
#import <CelestiaCore/CelestiaPlanetarySystem.h>
#import <CelestiaCore/CelestiaBody.h>
#import <CelestiaCore/CelestiaLocation.h>
#import <CelestiaCore/CelestiaStar.h>
#import <CelestiaCore/CelestiaGalaxy.h>
#import <CelestiaCore/CelestiaDSO.h>
#import <CelestiaCore/CelestiaOrbit.h>
#import <CelestiaCore/CelestiaRotationModel.h>
#import <CelestiaCore/CelestiaTimeline.h>
#import <CelestiaCore/CelestiaTimelinePhase.h>

#import <CelestiaCore/CelestiaEclipseFinder.h>
#import <CelestiaCore/CelestiaStarBrowser.h>
#import <CelestiaCore/CelestiaDSOCatalog.h>
#import <CelestiaCore/CelestiaStarCatalog.h>

#import <CelestiaCore/CelestiaDestination.h>

#import <CelestiaCore/CelestiaFont.h>
