// CelestiaDSOCatalog.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaDSO;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DSOCatalog)
@interface CelestiaDSOCatalog : NSObject

@property (readonly) NSInteger count;

- (CelestiaDSO *)objectAtIndex:(NSInteger)index;

- (NSString *)dsoName:(CelestiaDSO *)dso localized:(BOOL)localized;

@end

NS_ASSUME_NONNULL_END
