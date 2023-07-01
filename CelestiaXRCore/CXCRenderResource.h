//
// CXCRenderResource.h
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import <Metal/Metal.h>
#import <libEGL/libEGL.h>
#import <libGLESv2/libGLESv2.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXCRenderResource : NSObject

@property (readonly) id<MTLDevice> device;
@property (readonly) id<MTLCommandQueue> commandQueue;

@property (readonly) EGLContext eglContext;
@property (readonly) EGLDisplay eglDisplay;

@property (readonly) GLuint postprocessProgram;
@property (readonly) GLuint postprocessProgramVAO;
@property (readonly) GLuint postprocessProgramVBO;
@property (readonly) GLuint postprocessProgramTextureLocation;

- (BOOL)prepare;
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
