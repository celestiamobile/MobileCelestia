// CXCRenderResource.m
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import "CXCRenderResource.h"

@interface CXCRenderResource ()
@end

@implementation CXCRenderResource

- (instancetype)init {
    self = [super init];
    if (self) {
        _device = nil;
        _commandQueue = nil;
        _supportsRasterizationRateMap = NO;
#ifdef RENDER_USE_SHADER
        _pipelineState = nil;
        _vertexBuffer = nil;
#endif
        _eglContext = EGL_NO_CONTEXT;
        _eglDisplay = EGL_NO_DISPLAY;
    }
    return self;
}

- (void)cleanup {
    [self cleanupMetal];
    [self cleanupEGL];
}

- (BOOL)prepare {
    BOOL success = [self prepareEGL];
    if (!success)
        return NO;
    success = [self prepareMetal];
    if (!success) {
        [self cleanupEGL];
        return NO;
    }
    return YES;
}

- (BOOL)prepareMetal {
    EGLAttrib angleDevice = 0;
    if (eglQueryDisplayAttribEXT(_eglDisplay, EGL_DEVICE_EXT, &angleDevice) != EGL_TRUE)
        return NO;

    EGLAttrib device = 0;
    if (eglQueryDeviceAttribEXT((EGLDeviceEXT)angleDevice, EGL_METAL_DEVICE_ANGLE, &device) != EGL_TRUE)
        return NO;

    _device = (__bridge id<MTLDevice>)(void *)device;
    _commandQueue = [_device newCommandQueue];
    _supportsRasterizationRateMap = [_device supportsRasterizationRateMapWithLayerCount:1];

#ifdef RENDER_USE_SHADER
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

    id<MTLLibrary> library = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = sizeof(float) * 2;
    vertexDescriptor.layouts[0].stride = sizeof(float) * 4;
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;

    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:NULL];

    if (_pipelineState == nil)
    {
        [self cleanupMetal];
        return NO;
    }

    static const float vertices[] =
    {
        // Positions,   texture coordinates
        1.0f,  -1.0f,   1.f, 1.f,
       -1.0f,  -1.0f,   0.f, 1.f,
       -1.0f,   1.0f,   0.f, 0.f,

        1.0f,  -1.0f,   1.f, 1.f,
       -1.0f,   1.0f,   0.f, 0.f,
        1.0f,   1.0f,   1.f, 0.f,
    };
    _vertexBuffer = [_device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
    if (_vertexBuffer == nil) {
        [self cleanupMetal];
        return NO;
    }
#endif
    return YES;
}

- (BOOL)prepareEGL {
    EGLAttrib displayAttribs[] = { EGL_NONE };
    _eglDisplay = eglGetPlatformDisplay(EGL_PLATFORM_ANGLE_ANGLE, NULL, displayAttribs);
    if (_eglDisplay == EGL_NO_DISPLAY) {
        NSLog(@"eglGetPlatformDisplay() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    if (!eglInitialize(_eglDisplay, NULL, NULL)) {
        NSLog(@"eglInitialize() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    EGLConfig config = 0;
    EGLint configAttribs[] =
    {
        EGL_BLUE_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_RED_SIZE, 8,
        EGL_DEPTH_SIZE, 24,
        EGL_NONE
    };
    EGLint numConfigs;
    if (!eglChooseConfig(_eglDisplay, configAttribs, &config, 1, &numConfigs)) {
        NSLog(@"eglChooseConfig() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    EGLint ctxAttribs[] = { EGL_CONTEXT_MAJOR_VERSION, 2, EGL_CONTEXT_MINOR_VERSION, 0, EGL_NONE };
    _eglContext = eglCreateContext(_eglDisplay, config, EGL_NO_CONTEXT, ctxAttribs);
    if (_eglContext == EGL_NO_CONTEXT) {
        NSLog(@"eglCreateContext() returned error %d", eglGetError());
        [self cleanupEGL];
        return NO;
    }

    eglMakeCurrent(_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, _eglContext);
    eglSwapInterval(_eglDisplay, 0);
    return YES;
}

- (void)cleanupMetal {
#ifdef RENDER_USE_SHADER
    _vertexBuffer = nil;
    _pipelineState = nil;
#endif
}

- (void)cleanupEGL {
    if (_eglContext != EGL_NO_CONTEXT) {
        eglMakeCurrent(_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(_eglDisplay, _eglContext);
        _eglContext = EGL_NO_CONTEXT;
    }

    if (_eglDisplay != EGL_NO_DISPLAY) {
        eglTerminate(_eglDisplay);
        _eglDisplay = EGL_NO_DISPLAY;
    }
}

@end
