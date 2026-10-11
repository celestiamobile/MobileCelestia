// CelestiaStarCatalog.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaStar;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(StarCatalog)
@interface CelestiaStarCatalog : NSObject

@property (readonly) NSInteger count;

- (CelestiaStar *)objectAtIndex:(NSInteger)index;

- (NSString *)starName:(CelestiaStar *)star localized:(BOOL)localized;

@end

NS_ASSUME_NONNULL_END
