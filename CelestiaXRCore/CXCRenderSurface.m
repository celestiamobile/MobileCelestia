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

- (instancetype)initWithEGLColorImage:(EGLImageKHR)eglColorImage
                        eglDepthImage:(EGLImageKHR)eglDepthImage
                  glColorRenderBuffer:(GLuint)glColorRenderBuffer
                  glDepthRenderBuffer:(GLuint)glDepthRenderBuffer
                        glFrameBuffer:(GLuint)glFrameBuffer
            glSampleColorRenderBuffer:(GLuint)glSampleColorRenderBuffer
            glSampleDepthRenderBuffer:(GLuint)glSampleDepthRenderBuffer
                  glSampleFrameBuffer:(GLuint)glSampleFrameBuffer
                    metalColorTexture:(id<MTLTexture>)metalColorTexture
                    metalDepthTexture:(id<MTLTexture>)metalDepthTexture
                          screenWidth:(NSUInteger)screenWidth
                         screenHeight:(NSUInteger)screenHeight
                        physicalWidth:(NSUInteger)physicalWidth
                       physicalHeight:(NSUInteger)physicalHeight
                     metalSharedEvent:(id<MTLEvent>)metalSharedEvent
                          signalValue:(uint64_t)signalValue {
    self = [super init];
    if (self) {
        _eglColorImage = eglColorImage;
        _eglDepthImage = eglDepthImage;
        _glColorRenderBuffer = glColorRenderBuffer;
        _glDepthRenderBuffer = glDepthRenderBuffer;
        _glSampleColorRenderBuffer = glSampleColorRenderBuffer;
        _glSampleDepthRenderBuffer = glSampleDepthRenderBuffer;
        _glSampleFrameBuffer = glSampleFrameBuffer;
        _metalColorTexture = metalColorTexture;
        _metalDepthTexture = metalDepthTexture;
        _glFrameBuffer = glFrameBuffer;
        _screenWidth = screenWidth;
        _screenHeight = screenHeight;
        _physicalWidth = physicalWidth;
        _physicalHeight = physicalHeight;
        _metalSharedEvent = metalSharedEvent;
        _signalValue = signalValue;
    }
    return self;
}
@end
