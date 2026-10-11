// CEZZipUtils.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CEZZipErrorDomain;
extern NSErrorUserInfoKey const CEZZipErrorContextPathKey;

typedef NS_ERROR_ENUM(CEZZipErrorDomain, CEZZipErrorCode) {
    CEZZipErrorCodeZip              = 1,
    CEZZipErrorCodeCreateDirectory  = 2,
    CEZZipErrorCodeOpenFile         = 3,
    CEZZipErrorCodeWriteFile        = 4,
};

NS_SWIFT_NAME(ZipUtils)
@interface CEZZipUtils : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (BOOL)unzip:(NSString *)sourcePath destinationPath:(NSString *)destinationPath error:(NSError **)error NS_SWIFT_NAME(unzip(_:to:));

@end

NS_ASSUME_NONNULL_END
