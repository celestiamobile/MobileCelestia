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

#import <libEGL/libEGL.h>
#import <libGLESv2/libGLESv2.h>
#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXCRendererSurface : NSObject

@property (nonatomic) EGLImageKHR eglColorImage;
@property (nonatomic) EGLImageKHR eglDepthImage;
@property (nonatomic) GLuint glColorRenderBuffer;
@property (nonatomic) GLuint glDepthRenderBuffer;
@property (nonatomic) GLuint glFrameBuffer;
@property (nonatomic) GLuint glSampleColorRenderBuffer;
@property (nonatomic) GLuint glSampleDepthRenderBuffer;
@property (nonatomic) GLuint glSampleFrameBuffer;
@property (nonatomic) id<MTLTexture> metalColorTexture;
@property (nonatomic) id<MTLTexture> metalDepthTexture;
@property (nonatomic) NSUInteger screenWidth;
@property (nonatomic) NSUInteger screenHeight;
@property (nonatomic) NSUInteger physicalWidth;
@property (nonatomic) NSUInteger physicalHeight;
@property (nonatomic) id<MTLEvent> metalSharedEvent;
@property (nonatomic) uint64_t signalValue;

- (instancetype)init NS_UNAVAILABLE;
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
                        physicalWidth:(NSUInteger)screenWidth
                       physicalHeight:(NSUInteger)screenHeight
                     metalSharedEvent:(id<MTLEvent>)metalSharedEvent
                          signalValue:(uint64_t)signalValue;

@end

NS_ASSUME_NONNULL_END
