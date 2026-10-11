// CelestiaEclipseFinder.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import <Foundation/Foundation.h>

@class CelestiaBody;

typedef NS_OPTIONS(NSUInteger, CelestiaEclipseKind) {
    CelestiaEclipseKindSolar = 1 << 0,
    CelestiaEclipseKindLunar = 1 << 1,
} NS_SWIFT_NAME(EclipseKind);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_SENDABLE
NS_SWIFT_NAME(Eclipse)
@interface CelestiaEclipse : NSObject

@property (readonly) CelestiaBody *occulter;
@property (readonly) CelestiaBody *receiver;

@property (readonly) NSDate *startTime;
@property (readonly) NSDate *endTime;

@end

NS_SWIFT_NAME(EclipseFinder)
@interface CelestiaEclipseFinder : NSObject

- (instancetype)initWithBody:(CelestiaBody *)body;

- (NSArray<CelestiaEclipse *> *)search:(CelestiaEclipseKind)kind fromStart:(NSDate *)startTime toEnd:(NSDate *)endTime NS_SWIFT_NAME(search(kind:from:to:));

- (void)abort;

@end

NS_ASSUME_NONNULL_END
