//
//  AsyncGLAPI.h
//  AsyncGL
//
//  Created by Levin Li on 2023/2/7.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, AsyncGLAPI) {
    AsyncGLAPIOpenGLES2     = 1,
    AsyncGLAPIOpenGLES3     = 2,
    AsyncGLAPIOpenGLLegacy  = 3,
    AsyncGLAPIOpenGLCore32  = 4,
    AsyncGLAPIOpenGLCore41  = 5,
};
