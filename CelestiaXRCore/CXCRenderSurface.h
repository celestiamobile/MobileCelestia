//
// CXCRenderSurface.h
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

@interface CXCRendererSurface : NSObject

@property MTLRenderPassDescriptor *renderPassDescriptor;
@property EGLImageKHR eglColorImage;
@property EGLImageKHR eglDepthImage;
@property GLuint glColorTexture;
@property GLuint glIntermediateColorTexture;
@property GLuint glDepthTexture;
@property GLuint glFramebuffer;
@property GLint width;
@property GLint height;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor eglColorImage:(EGLImageKHR)eglColorImage eglDepthImage:(EGLImageKHR)eglDepthImage glColorTexture:(GLuint)glColorTexture glDepthTexture:(GLuint)glDepthTexture glIntermediateColorTexture:(GLuint)glIntermediateColorTexture glFramebuffer:(GLuint)glFramebuffer width:(GLint)width height:(GLint)height;

@end

NS_ASSUME_NONNULL_END
