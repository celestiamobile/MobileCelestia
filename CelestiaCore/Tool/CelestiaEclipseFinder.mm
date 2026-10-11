// CelestiaEclipseFinder.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#import "CelestiaUtil.h"
#import "CelestiaEclipseFinder.h"
#import "CelestiaBody+Private.h"
#include "celestia/eclipsefinder.h"

#include <memory>

class EclipseSeacherWatcher;

@interface CelestiaEclipseFinder () {
    std::unique_ptr<EclipseSeacherWatcher> d;
    std::unique_ptr<EclipseFinder> s;
@public
    BOOL aborted;
}

@end

class EclipseSeacherWatcher: public EclipseFinderWatcher
{
public:
    EclipseSeacherWatcher(void *delegate) : EclipseFinderWatcher(), delegate(delegate) {}

    virtual Status eclipseFinderProgressUpdate(double t)
    {
        CelestiaEclipseFinder *searcher = (__bridge CelestiaEclipseFinder *)delegate;
        return searcher->aborted ? Status::AbortOperation : Status::ContinueOperation;
    };
private:
    void *delegate;
};

@implementation CelestiaEclipse

- (instancetype)initWithEclipse:(Eclipse *)eclipse {
    self = [super init];
    if (self) {
        _occulter = [[CelestiaBody alloc] initWithBody:eclipse->occulter];
        _receiver = [[CelestiaBody alloc] initWithBody:eclipse->receiver];
        _startTime = [NSDate dateWithJulian:eclipse->startTime];
        _endTime = [NSDate dateWithJulian:eclipse->endTime];
    }
    return self;
}

@end

@implementation CelestiaEclipseFinder

- (instancetype)initWithBody:(CelestiaBody *)body {
    self = [super init];
    if (self) {
        d = std::make_unique<EclipseSeacherWatcher>((__bridge void *)self);
        s = std::make_unique<EclipseFinder>([body body], d.get());
        aborted = YES;
    }
    return self;
}

- (NSArray<CelestiaEclipse *> *)search:(CelestiaEclipseKind)kind fromStart:(NSDate *)startTime toEnd:(NSDate *)endTime {
    aborted = NO;
    std::vector<Eclipse> results;
    s->findEclipses([startTime julianDay], [endTime julianDay], static_cast<Eclipse::Type>(kind), results);

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:results.size()];
    for (Eclipse &result: results) {
        [array addObject:[[CelestiaEclipse alloc] initWithEclipse:&result]];
    }
    aborted = YES;
    return array;
}

- (void)abort {
    aborted = YES;
}

@end
