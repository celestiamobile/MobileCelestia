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

//#define RENDER_USE_SHADER

#import <Metal/Metal.h>
#import <libEGL/libEGL.h>
#import <libGLESv2/libGLESv2.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXCRenderResource : NSObject

@property (readonly, nonatomic) id<MTLDevice> device;
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;
@property (readonly) BOOL supportsRasterizationRateMap;

#ifdef RENDER_USE_SHADER
@property (readonly, nonatomic) id<MTLRenderPipelineState> pipelineState;
@property (readonly, nonatomic) id<MTLBuffer> vertexBuffer;
#endif

@property (readonly, nonatomic) EGLContext eglContext;
@property (readonly, nonatomic) EGLDisplay eglDisplay;

- (BOOL)prepare;
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
