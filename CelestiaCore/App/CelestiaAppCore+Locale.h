// CelestiaAppCore+Locale.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <CelestiaCore/CelestiaAppCore.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
NSString *LocalizedFilename(NSString *originalName);
NSString *LocalizedString(NSString *originalString, NSString *domain);
NSString *LocalizedStringContext(NSString *originalString, NSString *context, NSString *domain);
#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
