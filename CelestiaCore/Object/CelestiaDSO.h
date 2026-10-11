// CelestiaDSO.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <CelestiaCore/CelestiaAstroObject.h>

@class CelestiaVector;

typedef NS_ENUM(NSUInteger, CelestiaDSOType) {
    CelestiaDSOTypeGalaxy,
    CelestiaDSOTypeGlobular,
    CelestiaDSOTypeNebula,
    CelestiaDSOTypeOpenCluster,
} NS_SWIFT_NAME(DSOType);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DSO)
@interface CelestiaDSO : CelestiaAstroObject

@property (readonly) NSString *type;
@property (readonly) CelestiaDSOType objectType;
@property (readonly) NSString *dsoDescription;

@property (readonly) CelestiaVector *position;

@end

NS_ASSUME_NONNULL_END
