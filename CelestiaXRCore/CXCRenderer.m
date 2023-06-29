//
// CXCRenderer.m
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
#import <ARKit/ARKit.h>
#import <Spatial/Spatial.h>

#import <CelestiaCore/CelestiaCore.h>

#import "CXCRenderer.h"

@interface CXCRendererSurface : NSObject
@property MTLRenderPassDescriptor *renderPassDescriptor;
@property EGLImageKHR eglColorImage;
@property EGLImageKHR eglDepthImage;
@property GLuint glColorTexture;
@property GLuint glDepthTexture;
@property GLuint glFramebuffer;
@property GLint width;
@property GLint height;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor eglColorImage:(EGLImageKHR)eglColorImage eglDepthImage:(EGLImageKHR)eglDepthImage glColorTexture:(GLuint)glColorTexture glDepthTexture:(GLuint)glDepthTexture glFramebuffer:(GLuint)glFramebuffer width:(GLint)width height:(GLint)height;
@end

@implementation CXCRendererSurface

- (instancetype)initWithRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor eglColorImage:(EGLImageKHR)eglColorImage eglDepthImage:(EGLImageKHR)eglDepthImage glColorTexture:(GLuint)glColorTexture glDepthTexture:(GLuint)glDepthTexture glFramebuffer:(GLuint)glFramebuffer width:(GLint)width height:(GLint)height {
    self = [super init];
    if (self) {
        _renderPassDescriptor = renderPassDescriptor;
        _eglColorImage = eglColorImage;
        _eglDepthImage = eglDepthImage;
        _glColorTexture = glColorTexture;
        _glDepthTexture = glDepthTexture;
        _glFramebuffer = glFramebuffer;
        _width = width;
        _height = height;
    }
    return self;
}
@end

@interface CXCRenderer ()
@property (readonly) cp_layer_renderer_t layerRenderer;
@property ar_session_t arSession;
@property ar_world_tracking_provider_t worldTrackingProvider;

@property CFTimeInterval lastRenderTime;
@property CFTimeInterval sceneTime;
@property id<MTLDevice> device;
@property id<MTLCommandQueue> commandQueue;

@property EGLContext eglContext;
@property EGLDisplay eglDisplay;

@property (readonly) NSString *resourceFolderPath;
@property (readonly) NSString *configFilePath;

@property dispatch_semaphore_t semaphore;

@property CelestiaAppCore *appCore;

@end

@implementation CXCRenderer

- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath {
    self = [super init];
    if (self) {
        _lastRenderTime = CACurrentMediaTime();
        _sceneTime = 0.0;
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _eglContext = EGL_NO_CONTEXT;
        _eglDisplay = EGL_NO_DISPLAY;
        _appCore = [[CelestiaAppCore alloc] init];
        _resourceFolderPath = resourceFolderPath;
        _configFilePath = configFilePath;
        _semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)main {
    [self runWorldTrackingARSession];
    [self prepareResources];
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    BOOL isRunning = YES;
    while (isRunning) {
        @autoreleasepool {
            switch (cp_layer_renderer_get_state(_layerRenderer)) {
                case cp_layer_renderer_state_paused:
                    cp_layer_renderer_wait_until_running(_layerRenderer);
                    break;
                case cp_layer_renderer_state_running:
                    [self renderFrame];
                    break;
                case cp_layer_renderer_state_invalidated:
                    isRunning = false;
                    break;
            }
        }
    }
}

- (void)startRenderingWithLayerRenderer:(cp_layer_renderer_t)layerRenderer {
    _layerRenderer = layerRenderer;
    dispatch_semaphore_signal(_semaphore);
}

- (void)prepareResources {
    if (_eglDisplay == EGL_NO_DISPLAY)
    {
        EGLAttrib displayAttribs[] = { EGL_NONE };
        _eglDisplay = eglGetPlatformDisplay(EGL_PLATFORM_ANGLE_ANGLE, NULL, displayAttribs);
        eglInitialize(_eglDisplay, NULL, NULL);
    }

    if (_eglContext == EGL_NO_CONTEXT)
    {
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
        eglChooseConfig(_eglDisplay, configAttribs, &config, 1, &numConfigs);

        EGLint ctxAttribs[] = { EGL_CONTEXT_MAJOR_VERSION, 2, EGL_CONTEXT_MINOR_VERSION, 0, EGL_CONTEXT_OPENGL_NO_ERROR_KHR, EGL_TRUE, EGL_NONE };
        _eglContext = eglCreateContext(_eglDisplay, config, EGL_NO_CONTEXT, ctxAttribs);
    }

    eglMakeCurrent(_eglDisplay, NULL, NULL, _eglContext);
    [CelestiaAppCore initGL];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:_resourceFolderPath];
    [_appCore startSimulationWithConfigFileName:_configFilePath extraDirectories:nil progressReporter:^(NSString * _Nonnull progress) {
        NSLog(@"Loading %@", progress);
    }];
    [_appCore startRenderer];
    [_appCore start];
}

- (void)runWorldTrackingARSession {
    ar_world_tracking_configuration_t worldTrackingConfiguration = ar_world_tracking_configuration_create();
    _worldTrackingProvider = ar_world_tracking_provider_create(worldTrackingConfiguration);

    ar_data_providers_t dataProviders = ar_data_providers_create_with_providers(_worldTrackingProvider, nil);

    _arSession = ar_session_create();
    ar_session_run(_arSession, dataProviders);
}

- (ar_pose_t)createPoseForTiming:(cp_frame_timing_t)timing {
    ar_pose_t outPose = ar_pose_create();
    cp_time_t presentationTime = cp_frame_timing_get_presentation_time(timing);
    CFTimeInterval queryTime = cp_time_to_cf_time_interval(presentationTime);
    ar_pose_status_t status = ar_world_tracking_provider_query_pose_at_timestamp(_worldTrackingProvider, queryTime, outPose);
    if (status != ar_pose_status_success) {
        NSLog(@"Failed to get estimated pose from world tracking provider for presentation timestamp %0.3f", queryTime);
    }
    return outPose;
}

- (void)renderFrame {
    cp_frame_t frame = cp_layer_renderer_query_next_frame(_layerRenderer);
    if (!frame) {
        return;
    }

    cp_frame_timing_t timing = cp_frame_predict_timing(frame);
    if (!timing) {
        return;
    }

    cp_frame_start_update(frame);
    cp_frame_end_update(frame);

    cp_time_wait_until(cp_frame_timing_get_optimal_input_time(timing));

    cp_frame_start_submission(frame);
    cp_drawable_t drawable = cp_frame_query_drawable(frame);
    if (!drawable) {
        return;
    }

    cp_frame_timing_t actualTiming = cp_drawable_get_frame_timing(drawable);

    ar_pose_t pose = [self createPoseForTiming:actualTiming];
    cp_drawable_set_ar_pose(drawable, pose);

    NSArray<CXCRendererSurface *> *resources = [self drawAndPresentFrame:frame drawable:drawable];

    cp_frame_end_submission(frame);

    for (CXCRendererSurface *resource in resources)
    {
        GLuint framebuffer = resource.glFramebuffer;
        glDeleteFramebuffers(1, &framebuffer);
        GLuint textures[] = { resource.glColorTexture, resource.glDepthTexture };
        glDeleteTextures(2, textures);
        eglDestroyImageKHR(_eglDisplay, resource.eglColorImage);
        eglDestroyImageKHR(_eglDisplay, resource.eglDepthImage);
    }
}

- (NSArray<CXCRendererSurface *> *)drawAndPresentFrame:(cp_frame_t)frame drawable:(cp_drawable_t)drawable {
    CFTimeInterval renderTime = CACurrentMediaTime();
    CFTimeInterval timestep = MIN(renderTime - _lastRenderTime, 1.0 / 60.0);
    _sceneTime += timestep;

    [_appCore tick];

    ar_pose_t arPose = cp_drawable_get_ar_pose(drawable);
    simd_float4x4 poseTransform = ar_pose_get_origin_from_device_transform(arPose);

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    NSMutableArray *resources = [NSMutableArray array];
    for (int i = 0; i < cp_drawable_get_view_count(drawable); ++i)
    {
        CXCRendererSurface *renderSurface = [self createRenderPassDescriptorForDrawable:drawable index:i];
        cp_view_t view = cp_drawable_get_view(drawable, i);
        simd_float4 tangents = cp_view_get_tangents(view);
        simd_float2 depthRange = cp_drawable_get_depth_range(drawable);
        [_appCore resize:CGSizeMake(renderSurface.width, renderSurface.height)];
        [_appCore setCustomPerspectiveProjectionLeft:-tangents[0] * depthRange[1] right:tangents[1] * depthRange[1] top:tangents[2] * depthRange[1] bottom:-tangents[3] * depthRange[1] nearZ:depthRange[1] farZ:depthRange[0]];

        simd_float4x4 cameraMatrix = simd_mul(poseTransform, cp_view_get_transform(view));
        [_appCore setCameraTransform:simd_inverse(cameraMatrix)];
        [_appCore draw];

        [resources addObject:renderSurface];
    }

    glFinish();

    cp_drawable_encode_present(drawable, commandBuffer);
    [commandBuffer commit];

    return [resources copy];
}

- (CXCRendererSurface *)createRenderPassDescriptorForDrawable:(cp_drawable_t)drawable index:(size_t)index {
    MTLRenderPassDescriptor *passDescriptor = [[MTLRenderPassDescriptor alloc] init];

    id<MTLTexture> colorTexture = cp_drawable_get_color_texture(drawable, index);
    id<MTLTexture> depthTexture = cp_drawable_get_depth_texture(drawable, index);

    passDescriptor.colorAttachments[0].texture = colorTexture;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    passDescriptor.depthAttachment.texture = depthTexture;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;

    passDescriptor.renderTargetArrayLength = cp_drawable_get_view_count(drawable);
    passDescriptor.rasterizationRateMap = cp_drawable_get_rasterization_rate_map(drawable, index);

    eglMakeCurrent(_eglDisplay, NULL, NULL, _eglContext);

    const EGLint emptyAttributes[] = { EGL_NONE };
    EGLImageKHR eglColorImage = eglCreateImageKHR(_eglDisplay, EGL_NO_CONTEXT, EGL_METAL_TEXTURE_ANGLE, (__bridge EGLClientBuffer)colorTexture, emptyAttributes);
    EGLImageKHR eglDepthImage = eglCreateImageKHR(_eglDisplay, EGL_NO_CONTEXT, EGL_METAL_TEXTURE_ANGLE, (__bridge EGLClientBuffer)depthTexture, emptyAttributes);

    GLuint glColorTexture;
    glGenTextures(1, &glColorTexture);
    glBindTexture(GL_TEXTURE_2D, glColorTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, eglColorImage);
    GLuint glDepthTexture;
    glGenTextures(1, &glDepthTexture);
    glBindTexture(GL_TEXTURE_2D, glDepthTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, eglDepthImage);
    GLuint glFramebuffer;
    glGenFramebuffers(1, &glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, glFramebuffer);
    glFramebufferParameteri(GL_FRAMEBUFFER, GL_FRAMEBUFFER_FLIP_Y_MESA, 1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, glColorTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, glDepthTexture, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    return [[CXCRendererSurface alloc] initWithRenderPassDescriptor:passDescriptor eglColorImage:eglColorImage eglDepthImage:eglDepthImage glColorTexture:glColorTexture glDepthTexture:glDepthTexture glFramebuffer:glFramebuffer width:(GLint)colorTexture.width height:(GLint)colorTexture.height];
}

@end

CXCRenderer *CXC_RendererStart(NSString *resourceFolderPath, NSString *configFilePath)
{
    CXCRenderer *renderer = [[CXCRenderer alloc] initWithResourceFolderPath:resourceFolderPath configFilePath:configFilePath];
    [renderer setName:@"CXCRenderer"];
    [renderer start];
    return renderer;
}
