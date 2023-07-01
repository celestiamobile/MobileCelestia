//
// CXCRenderSurface.m
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CXCRenderSurface.h"

@implementation CXCRendererSurface

- (instancetype)initWithRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor eglColorImage:(EGLImageKHR)eglColorImage eglDepthImage:(EGLImageKHR)eglDepthImage glColorTexture:(GLuint)glColorTexture glDepthTexture:(GLuint)glDepthTexture glIntermediateColorTexture:(GLuint)glIntermediateColorTexture glFramebuffer:(GLuint)glFramebuffer width:(GLint)width height:(GLint)height {
    self = [super init];
    if (self) {
        _renderPassDescriptor = renderPassDescriptor;
        _eglColorImage = eglColorImage;
        _eglDepthImage = eglDepthImage;
        _glColorTexture = glColorTexture;
        _glDepthTexture = glDepthTexture;
        _glIntermediateColorTexture = glIntermediateColorTexture;
        _glFramebuffer = glFramebuffer;
        _width = width;
        _height = height;
    }
    return self;
}
@end
