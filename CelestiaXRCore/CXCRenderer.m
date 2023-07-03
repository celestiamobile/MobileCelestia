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

#import <CelestiaCore/CelestiaCore.h>

#import "CXCRenderer.h"
#import "CXCRenderResource.h"
#import "CXCRenderSurface.h"

#include <os/lock.h>

@interface CXCRenderer () {
    CXCRendererStatus _renderStatus;
    void (^_selectionUpdater)(CelestiaSelection *);
    void (^_statusUpdater)(CXCRendererStatus);
    void (^_fileNameUpdater)(NSString *);
}

@property os_unfair_lock resourceLock;

@property NSThread *renderThread;
@property CXCRenderResource *renderResource;

@property cp_layer_renderer_t layerRenderer;

@property ar_session_t arSession;
@property ar_world_tracking_provider_t worldTrackingProvider;

@property NSString *resourceFolderPath;
@property NSString *configFilePath;

@property dispatch_semaphore_t renderSemaphore;

@property CelestiaSelection *selection;
@property NSMutableArray<void (^)(CelestiaAppCore *)> *tasks;

@property BOOL inheritedFromPreviousRenderer;

@end

@implementation CXCRenderer

- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath {
    self = [super init];
    if (self) {
        _renderResource = [[CXCRenderResource alloc] init];
        _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(main) object:nil];
        _renderSemaphore = dispatch_semaphore_create(0);

        _arSession = NULL;
        _worldTrackingProvider = NULL;

        _layerRenderer = NULL;

        _appCore = [[CelestiaAppCore alloc] init];
        _selection = [[CelestiaSelection alloc] init];

        _resourceFolderPath = resourceFolderPath;
        _configFilePath = configFilePath;

        _renderStatus = CXCRendererStatusNone;
        _resourceLock = OS_UNFAIR_LOCK_INIT;
        _tasks = [NSMutableArray array];

        _inheritedFromPreviousRenderer = NO;
    }
    return self;
}

- (instancetype)initRenderer:(CXCRenderer *)renderer {
    self = [super init];
    if (self) {
        _renderResource = renderer.renderResource;
        _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(main) object:nil];
        _renderSemaphore = dispatch_semaphore_create(0);

        _arSession = renderer.arSession;
        _worldTrackingProvider = NULL;

        _layerRenderer = NULL;

        _appCore = renderer.appCore;

        _resourceFolderPath = renderer.resourceFolderPath;
        _configFilePath = renderer.configFilePath;

        _renderStatus = CXCRendererStatusNone;
        _resourceLock = OS_UNFAIR_LOCK_INIT;
        _tasks = [NSMutableArray array];

        _inheritedFromPreviousRenderer = YES;
    }
    return self;
}

- (CXCRendererStatus)status {
    os_unfair_lock_lock(&_resourceLock);
    os_unfair_lock_lock(&_resourceLock);;
    CXCRendererStatus current = _renderStatus;
    os_unfair_lock_unlock(&_resourceLock);;
    return current;
}

- (void)setStatus:(CXCRendererStatus)status {
    os_unfair_lock_lock(&_resourceLock);;
    _renderStatus = status;
    if (_statusUpdater != nil) {
        _statusUpdater(status);
    }
    os_unfair_lock_unlock(&_resourceLock);;
}

- (void (^)(CXCRendererStatus))statusUpdater {
    os_unfair_lock_lock(&_resourceLock);;
    void (^updater)(CXCRendererStatus) = _statusUpdater;
    os_unfair_lock_unlock(&_resourceLock);;
    return updater;
}

- (void)setStatusUpdater:(void (^)(CXCRendererStatus))statusUpdater {
    os_unfair_lock_lock(&_resourceLock);;
    _statusUpdater = statusUpdater;
    os_unfair_lock_unlock(&_resourceLock);;
}

- (void (^)(NSString * _Nonnull))fileNameUpdater {
    os_unfair_lock_lock(&_resourceLock);;
    void (^updater)(NSString * _Nonnull) = _fileNameUpdater;
    os_unfair_lock_unlock(&_resourceLock);;
    return updater;
}

- (void)setFileNameUpdater:(void (^)(NSString * _Nonnull))fileNameUpdater {
    os_unfair_lock_lock(&_resourceLock);;
    _fileNameUpdater = fileNameUpdater;
    os_unfair_lock_unlock(&_resourceLock);;
}

- (void (^)(CelestiaSelection * _Nonnull))selectionUpdater {
    os_unfair_lock_lock(&_resourceLock);;
    void (^updater)(CelestiaSelection * _Nonnull) = _selectionUpdater;
    os_unfair_lock_unlock(&_resourceLock);;
    return updater;
}

- (void)setSelectionUpdater:(void (^)(CelestiaSelection * _Nonnull))selectionUpdater {
    os_unfair_lock_lock(&_resourceLock);;
    _selectionUpdater = selectionUpdater;
    os_unfair_lock_unlock(&_resourceLock);;
}

- (void)enqueueTask:(void (^)(CelestiaAppCore * _Nonnull))task {
    os_unfair_lock_lock(&_resourceLock);;
    [_tasks addObject:task];
    os_unfair_lock_unlock(&_resourceLock);;
}

- (void)prepare {
    [_renderThread setName:@"CXCRenderer"];
    [_renderThread start];
    [self setStatus:CXCRendererStatusLoading];
}

- (void)main {
    [self runWorldTrackingARSession];

    if (!_inheritedFromPreviousRenderer) {
        if (![_renderResource prepare]) {
            [self stopWorldTrackingARSession];
            [self setStatus:CXCRendererStatusNone];
            return;
        }

        if (![self prepareCelestia]) {
            [_renderResource cleanup];
            [self stopWorldTrackingARSession];
            [self setStatus:CXCRendererStatusNone];
            return;
        }
    }

    [self setStatus:CXCRendererStatusLoaded];

    dispatch_semaphore_wait(_renderSemaphore, DISPATCH_TIME_FOREVER);
    [self setStatus:CXCRendererStatusRendering];

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
                    isRunning = NO;
                    break;
            }
        }
    }
    [self setStatus:CXCRendererStatusInvalidated];
}

- (void)startRenderingWithLayerRenderer:(cp_layer_renderer_t)layerRenderer {
    _layerRenderer = layerRenderer;
    dispatch_semaphore_signal(_renderSemaphore);
}

- (BOOL)prepareCelestia {
    if (![CelestiaAppCore initGL]) {
        NSLog(@"Error calling [CelestiaAppCore initGL]");
        [self cleanupCelestia];
        return NO;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *oldCurrentDirectory = [fileManager currentDirectoryPath];
    if (![fileManager changeCurrentDirectoryPath:_resourceFolderPath]) {
        NSLog(@"Error changing current directory");
        [self cleanupCelestia];
        return NO;
    }
    if (![_appCore startSimulationWithConfigFileName:_configFilePath extraDirectories:nil progressReporter:^(NSString * _Nonnull progress) {
        void (^updater)(NSString * _Nonnull) = [self fileNameUpdater];
        if (updater != nil)
            updater(progress);
    }]) {
        NSLog(@"Error preparing simulation");
        [self cleanupCelestia];
        [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];
        return NO;
    }
    if (![_appCore startRenderer]) {
        NSLog(@"Error preparing Celestia renderer");
        [self cleanupCelestia];
        [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];
        return NO;
    }
    [_appCore start];
    return YES;
}

- (void)cleanupCelestia {
}

- (void)runWorldTrackingARSession {
    ar_world_tracking_configuration_t worldTrackingConfiguration = ar_world_tracking_configuration_create();
    _worldTrackingProvider = ar_world_tracking_provider_create(worldTrackingConfiguration);

    ar_data_providers_t dataProviders = ar_data_providers_create_with_providers(_worldTrackingProvider, nil);

    _arSession = ar_session_create();
    ar_session_run(_arSession, dataProviders);
}

- (void)stopWorldTrackingARSession {
    ar_session_stop_all_data_providers(_arSession);
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

    for (CXCRendererSurface *resource in resources) {
        GLuint framebuffer = resource.glFramebuffer;
        glDeleteFramebuffers(1, &framebuffer);
        GLuint textures[] = { resource.glColorTexture, resource.glDepthTexture, resource.glIntermediateColorTexture };
        glDeleteTextures(3, textures);
        eglDestroyImageKHR(_renderResource.eglDisplay, resource.eglColorImage);
        eglDestroyImageKHR(_renderResource.eglDisplay, resource.eglDepthImage);
    }
}

- (NSArray<CXCRendererSurface *> *)drawAndPresentFrame:(cp_frame_t)frame drawable:(cp_drawable_t)drawable {
    os_unfair_lock_lock(&_resourceLock);;
    NSArray<void (^)(CelestiaAppCore *)> *taskCopy = [_tasks copy];
    [_tasks removeAllObjects];
    os_unfair_lock_unlock(&_resourceLock);;

    for (void (^task)(CelestiaAppCore *) in taskCopy)
        task(_appCore);

    [_appCore tick];

    CelestiaSelection *newSelection = [[_appCore simulation] selection];
    if (_selection == nil || ![newSelection isEqualToSelection:_selection]) {
        _selection = newSelection;
        void (^updater)(CelestiaSelection * _Nonnull) = [self selectionUpdater];
        if (updater != nil)
            updater(newSelection);
    }

    ar_pose_t arPose = cp_drawable_get_ar_pose(drawable);
    simd_float4x4 poseTransform = ar_pose_get_origin_from_device_transform(arPose);

    id<MTLCommandBuffer> commandBuffer = [_renderResource.commandQueue commandBuffer];

    [[_appCore simulation] setObserverTransform:simd_inverse(poseTransform)];

    NSMutableArray *resources = [NSMutableArray array];
    for (int i = 0; i < cp_drawable_get_view_count(drawable); ++i) {
        CXCRendererSurface *renderSurface = [self createRenderPassDescriptorForDrawable:drawable index:i];
        cp_view_t view = cp_drawable_get_view(drawable, i);
        simd_float4 tangents = cp_view_get_tangents(view);
        simd_float2 depthRange = cp_drawable_get_depth_range(drawable);
        [_appCore resize:CGSizeMake(renderSurface.width, renderSurface.height)];
        [_appCore setCustomPerspectiveProjectionLeft:-tangents[0] * depthRange[1] right:tangents[1] * depthRange[1] top:tangents[2] * depthRange[1] bottom:-tangents[3] * depthRange[1] nearZ:depthRange[1] farZ:depthRange[0]];

        [_appCore setCameraTransform:simd_inverse(cp_view_get_transform(view))];
        [_appCore draw];

        glFlush();

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderSurface.glColorTexture, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, 0, 0);

        glViewport(0, 0, (GLsizei)renderSurface.width, (GLsizei)renderSurface.height);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glUseProgram(_renderResource.postprocessProgram);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, renderSurface.glIntermediateColorTexture);
        glUniform1i(_renderResource.postprocessProgramTextureLocation, 0);

        glBindVertexArray(_renderResource.postprocessProgramVAO);
        glDrawArrays(GL_TRIANGLES, 0, 6);
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindVertexArray(0);

        glFlush();

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

    eglMakeCurrent(_renderResource.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, _renderResource.eglContext);

    const EGLint emptyAttributes[] = { EGL_NONE };
    EGLImageKHR eglColorImage = eglCreateImageKHR(_renderResource.eglDisplay, EGL_NO_CONTEXT, EGL_METAL_TEXTURE_ANGLE, (__bridge EGLClientBuffer)colorTexture, emptyAttributes);
    EGLImageKHR eglDepthImage = eglCreateImageKHR(_renderResource.eglDisplay, EGL_NO_CONTEXT, EGL_METAL_TEXTURE_ANGLE, (__bridge EGLClientBuffer)depthTexture, emptyAttributes);

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

    GLuint glIntermediateColorTexture;
    glGenTextures(1, &glIntermediateColorTexture);
    glBindTexture(GL_TEXTURE_2D, glIntermediateColorTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)colorTexture.width, (GLsizei)colorTexture.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

    GLuint glFramebuffer;
    glGenFramebuffers(1, &glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, glFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, glIntermediateColorTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, glDepthTexture, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    return [[CXCRendererSurface alloc] initWithRenderPassDescriptor:passDescriptor eglColorImage:eglColorImage eglDepthImage:eglDepthImage glColorTexture:glColorTexture glDepthTexture:glDepthTexture glIntermediateColorTexture:glIntermediateColorTexture glFramebuffer:glFramebuffer width:(GLint)colorTexture.width height:(GLint)colorTexture.height];
}

@end
