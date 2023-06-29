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
#import "CXCFont.h"
#import "CXCFontCollection.h"
#import "CXCInputEvent.h"
#import "CXCRenderResource.h"
#import "CXCRenderSurface.h"

#include <os/lock.h>

@interface CXCRenderer () {
    CXCRendererStatus _renderStatus;
    void (^_stateUpdater)(CelestiaAppState *);
    void (^_statusUpdater)(CXCRendererStatus);
    void (^_fileNameUpdater)(NSString *);
    void (^_messageUpdater)(NSString *);
}

@property os_unfair_lock resourceLock;

@property NSThread *renderThread;
@property CXCRenderResource *renderResource;

@property cp_layer_renderer_t layerRenderer;

@property ar_session_t arSession;
@property ar_world_tracking_provider_t worldTrackingProvider;

@property NSString *resourceFolderPath;
@property NSString *configFilePath;
@property NSArray<NSString *> *extraDirectories;
@property NSUserDefaults *userDefaults;
@property NSString *appDefaultsPath;

@property dispatch_semaphore_t renderSemaphore;

@property CelestiaAppState *appState;
@property NSString *message;
@property NSMutableArray<void (^)(CelestiaAppCore *)> *tasks;

@property NSMutableArray<CXCInputEvent *> *currentEvents;
@property CXCInputEventPhase previousSingleEventPhase;
@property (nonatomic) simd_float3x3 currrentObserverTransform;

@property NSMutableArray<CXCRendererSurface *> *surfaces;

@property CXCFontCollection *defaultFonts;
@property NSDictionary<NSString *, CXCFontCollection *> *otherFonts;

@property (nonatomic) CFTimeInterval currentTime;

@end

@implementation CXCRenderer

- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath extraDirectories:(NSArray<NSString *> *)extraDirectories userDefaults:(NSUserDefaults *)userDefaults appDefaultsPath:(nullable NSString *)appDefaultsPath defaultFonts:(CXCFontCollection *)defaultFonts otherFonts:(NSDictionary<NSString *, CXCFontCollection *> *)otherFonts {
    self = [super init];
    if (self) {
        _renderResource = [[CXCRenderResource alloc] init];
        _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(main) object:nil];
        _renderSemaphore = dispatch_semaphore_create(0);

        _arSession = NULL;
        _worldTrackingProvider = NULL;

        _layerRenderer = NULL;

        _appCore = [[CelestiaAppCore alloc] init];
        _appState = nil;
        _message = @"";

        _resourceFolderPath = resourceFolderPath;
        _configFilePath = configFilePath;
        _userDefaults = userDefaults;
        _appDefaultsPath = appDefaultsPath;
        _extraDirectories = [extraDirectories copy];

        _renderStatus = CXCRendererStatusNone;
        _resourceLock = OS_UNFAIR_LOCK_INIT;
        _tasks = [NSMutableArray array];

        _currentEvents = [NSMutableArray array];
        _previousSingleEventPhase = CXCInputEventPhaseEnded;
        _currrentObserverTransform = matrix_identity_float3x3;
        _surfaces = [NSMutableArray array];

        _defaultFonts = defaultFonts;
        _otherFonts = [otherFonts copy];

        _currentTime = 0;
    }
    return self;
}

- (CXCRendererStatus)status {
    os_unfair_lock_lock(&_resourceLock);
    CXCRendererStatus current = _renderStatus;
    os_unfair_lock_unlock(&_resourceLock);
    return current;
}

- (void)setStatus:(CXCRendererStatus)status {
    os_unfair_lock_lock(&_resourceLock);
    _renderStatus = status;
    if (_statusUpdater != nil) {
        _statusUpdater(status);
    }
    os_unfair_lock_unlock(&_resourceLock);
}

- (void (^)(CXCRendererStatus))statusUpdater {
    os_unfair_lock_lock(&_resourceLock);
    void (^updater)(CXCRendererStatus) = _statusUpdater;
    os_unfair_lock_unlock(&_resourceLock);
    return updater;
}

- (void)setStatusUpdater:(void (^)(CXCRendererStatus))statusUpdater {
    os_unfair_lock_lock(&_resourceLock);
    _statusUpdater = statusUpdater;
    os_unfair_lock_unlock(&_resourceLock);
}

- (void (^)(NSString * _Nonnull))fileNameUpdater {
    os_unfair_lock_lock(&_resourceLock);
    void (^updater)(NSString * _Nonnull) = _fileNameUpdater;
    os_unfair_lock_unlock(&_resourceLock);
    return updater;
}

- (void)setFileNameUpdater:(void (^)(NSString * _Nonnull))fileNameUpdater {
    os_unfair_lock_lock(&_resourceLock);
    _fileNameUpdater = fileNameUpdater;
    os_unfair_lock_unlock(&_resourceLock);
}

- (void (^)(NSString * _Nonnull))messageUpdater {
    os_unfair_lock_lock(&_resourceLock);
    void (^updater)(NSString * _Nonnull) = _messageUpdater;
    os_unfair_lock_unlock(&_resourceLock);
    return updater;
}

- (void)setMessageUpdater:(void (^)(NSString * _Nonnull))messageUpdater {
    os_unfair_lock_lock(&_resourceLock);
    _messageUpdater = messageUpdater;
    os_unfair_lock_unlock(&_resourceLock);
}

- (void (^)(CelestiaAppState * _Nonnull))stateUpdater {
    os_unfair_lock_lock(&_resourceLock);
    void (^updater)(CelestiaAppState * _Nonnull) = _stateUpdater;
    os_unfair_lock_unlock(&_resourceLock);
    return updater;
}

- (void)setStateUpdater:(void (^)(CelestiaAppState * _Nonnull))stateUpdater {
    os_unfair_lock_lock(&_resourceLock);
    _stateUpdater = stateUpdater;
    os_unfair_lock_unlock(&_resourceLock);
}

- (void)enqueueEvents:(NSArray<CXCInputEvent *> *)events {
    os_unfair_lock_lock(&_resourceLock);
    [_currentEvents addObjectsFromArray:events];
    os_unfair_lock_unlock(&_resourceLock);
}

- (void)enqueueTask:(void (^)(CelestiaAppCore * _Nonnull))task {
    os_unfair_lock_lock(&_resourceLock);
    [_tasks addObject:task];
    os_unfair_lock_unlock(&_resourceLock);
}

- (void)prepare {
    [_renderThread setName:@"CXCRenderer"];
    [_renderThread start];
    [self setStatus:CXCRendererStatusLoading];
}

- (void)main {
    [self runWorldTrackingARSession];

    if (![_renderResource prepare]) {
        [self stopWorldTrackingARSession];
        [self setStatus:CXCRendererStatusFailed];
        return;
    }

    if (![self prepareCelestia]) {
        [_renderResource cleanup];
        [self stopWorldTrackingARSession];
        [self setStatus:CXCRendererStatusFailed];
        return;
    }

    [self setStatus:CXCRendererStatusLoaded];

    dispatch_semaphore_wait(_renderSemaphore, DISPATCH_TIME_FOREVER);
    [self setStatus:CXCRendererStatusRendering];

    eglMakeCurrent(_renderResource.eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, _renderResource.eglContext);

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
                    _renderSemaphore = dispatch_semaphore_create(0);
                    [self setStatus:CXCRendererStatusInvalidated];
                    dispatch_semaphore_wait(_renderSemaphore, DISPATCH_TIME_FOREVER);
                    [self setStatus:CXCRendererStatusRendering];
                    break;
            }
        }
    }
    [self cleanupSurfaces];
    [_renderResource cleanup];
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
    [CelestiaAppCore setLocaleDirectory:[_resourceFolderPath stringByAppendingPathComponent:@"locale"]];
    NSMutableArray<NSString *> *validExtraDirectories = [NSMutableArray array];
    for (NSString *extraDirectory in _extraDirectories) {
        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:extraDirectory isDirectory:&isDir]) {
            if (isDir) {
                [validExtraDirectories addObject:extraDirectory];
            }
        }
        else {
            if ([fileManager createDirectoryAtPath:extraDirectory withIntermediateDirectories:NO attributes:nil error:NULL]) {
                [validExtraDirectories addObject:extraDirectory];
            }
        }
    }
    _extraDirectories = validExtraDirectories;

    if (![_appCore startSimulationWithConfigFileName:_configFilePath extraDirectories:validExtraDirectories progressReporter:^(NSString * _Nonnull progress) {
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

    /* Load values from user defaults and default config */
    [_appCore loadUserDefaults:_userDefaults withAppDefaultsAtPath:_appDefaultsPath];

    /* Disable features that do not work well in XR */
    [_appCore setHudDetail:0];
    [_appCore setHudMessagesEnabled:NO];
    [_appCore disableSelectionPointer];
    [_appCore setHudOverlayImageEnabled:NO];

    /* Configure fonts */
    CXCFontCollection *fonts = [_otherFonts objectForKey:[CelestiaAppCore language]];
    if (fonts == nil)
        fonts = _defaultFonts;
    [_appCore setHudFont:fonts.mainFont.path collectionIndex:fonts.mainFont.index fontSize:fonts.mainFont.size];
    [_appCore setHudTitleFont:fonts.titleFont.path collectionIndex:fonts.titleFont.index fontSize:fonts.titleFont.size];
    [_appCore setRendererFont:fonts.normalRenderFont.path collectionIndex:fonts.normalRenderFont.index fontSize:fonts.normalRenderFont.size fontStyle:CelestiaRendererFontStyleNormal];
    [_appCore setRendererFont:fonts.largeRenderFont.path collectionIndex:fonts.largeRenderFont.index fontSize:fonts.largeRenderFont.size fontStyle:CelestiaRendererFontStyleLarge];

    [_appCore start];
    _currentTime = CACurrentMediaTime();
    return YES;
}

- (void)cleanupCelestia {
}

- (void)cleanupSurfaces {
    for (CXCRendererSurface *surface in _surfaces) {
        GLuint framebuffer = surface.glFramebuffer;
        glDeleteFramebuffers(1, &framebuffer);
        GLuint textures[] = { surface.glIntermediateColorTexture };
        glDeleteTextures(1, textures);
    }
    _surfaces = [NSMutableArray array];
}

- (void)runWorldTrackingARSession {
    ar_world_tracking_configuration_t worldTrackingConfiguration = ar_world_tracking_configuration_create();
    _worldTrackingProvider = ar_world_tracking_provider_create(worldTrackingConfiguration);

    ar_data_providers_t dataProviders = ar_data_providers_create_with_data_providers(_worldTrackingProvider, nil);

    _arSession = ar_session_create();
    ar_session_run(_arSession, dataProviders);
}

- (void)stopWorldTrackingARSession {
    ar_session_stop(_arSession);
}

- (ar_device_anchor_t)createPoseForTiming:(cp_frame_timing_t)timing {
    ar_device_anchor_t outPose = ar_device_anchor_create();
    cp_time_t presentationTime = cp_frame_timing_get_presentation_time(timing);
    CFTimeInterval queryTime = cp_time_to_cf_time_interval(presentationTime);
    ar_device_anchor_query_status_t status = ar_world_tracking_provider_query_device_anchor_at_timestamp(_worldTrackingProvider, queryTime, outPose);
    if (status != ar_device_anchor_query_status_success) {
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

    ar_device_anchor_t pose = [self createPoseForTiming:actualTiming];
    cp_drawable_set_device_anchor(drawable, pose);

    NSArray<CXCRendererSurface *> *resources = [self drawAndPresentFrame:frame drawable:drawable];

    cp_frame_end_submission(frame);

    for (CXCRendererSurface *resource in resources) {
        GLuint textures[] = { resource.glColorTexture, resource.glDepthTexture };
        glDeleteTextures(2, textures);
        eglDestroyImageKHR(_renderResource.eglDisplay, resource.eglColorImage);
        eglDestroyImageKHR(_renderResource.eglDisplay, resource.eglDepthImage);
    }
}

- (NSArray<CXCRendererSurface *> *)drawAndPresentFrame:(cp_frame_t)frame drawable:(cp_drawable_t)drawable {
    os_unfair_lock_lock(&_resourceLock);
    NSArray<void (^)(CelestiaAppCore *)> *tasks = nil;
    NSArray<CXCInputEvent *> *events = nil;
    if ([_tasks count] > 0) {
        tasks = _tasks;
        _tasks = [NSMutableArray array];
    }
    if ([_currentEvents count] > 0) {
        events = _currentEvents;
        _currentEvents = [NSMutableArray array];
    }
    os_unfair_lock_unlock(&_resourceLock);

    for (void (^task)(CelestiaAppCore *) in tasks)
        task(_appCore);

    for (CXCInputEvent *event in events) {
        simd_double3 original = event.focus.vector;
        simd_float3 focus = simd_mul(_currrentObserverTransform, simd_make_float3((float)original[0], (float)original[1], (float)original[2]));
        if ([event isKindOfClass:[CXCSingleTouchInputEvent class]]) {
            CXCSingleTouchInputEvent *singleTouchEvent = (CXCSingleTouchInputEvent *)event;
            CXCInputEventPhase currentPhase = singleTouchEvent.phase;
            switch (currentPhase)
            {
            case CXCInputEventPhaseActive:
                if (_previousSingleEventPhase == CXCInputEventPhaseEnded)
                    [_appCore touchDown:focus];
                [_appCore touchMove:focus from:singleTouchEvent.oldDirection.vector to:singleTouchEvent.newDirection.vector];
                break;
            case CXCInputEventPhaseEnded:
                {
                    if (_previousSingleEventPhase == CXCInputEventPhaseEnded)
                        [_appCore touchDown:focus];
                    [_appCore touchMove:focus from:singleTouchEvent.oldDirection.vector to:singleTouchEvent.newDirection.vector];
                    [_appCore touchUp:focus];
                }
            }
            _previousSingleEventPhase = currentPhase;
        } else if ([event isKindOfClass:[CXCDoubleTouchInputEvent class]]) {
            CXCDoubleTouchInputEvent *doubleTouchEvent = (CXCDoubleTouchInputEvent *)event;
            [_appCore pinchUpdate:focus scale:doubleTouchEvent.scale];
        }
    }

    cp_frame_timing_t timing = cp_drawable_get_frame_timing(drawable);
    CFTimeInterval presentationTime = cp_time_to_cf_time_interval(cp_frame_timing_get_presentation_time(timing));

    [_appCore tick:presentationTime - _currentTime];
    _currentTime = presentationTime;

    CelestiaAppState *newState = [_appCore state];
    if (_appState == nil || ![newState isEqual:_appState]) {
        _appState = newState;
        void (^updater)(CelestiaAppState * _Nonnull) = [self stateUpdater];
        if (updater != nil)
            updater(newState);
    }
    NSString *message = [_appCore currentMessageText];
    if (![_message isEqualToString:message]) {
        _message = message;
        void (^updater)(NSString * _Nonnull) = [self messageUpdater];
        if (updater != nil)
            updater(message);
    }

    ar_device_anchor_t arPose = cp_drawable_get_device_anchor(drawable);
    simd_float4x4 poseTransform = ar_anchor_get_origin_from_anchor_transform(arPose);
    simd_float4x4 inversedTransform = simd_inverse(poseTransform);
    _currrentObserverTransform = simd_matrix(simd_make_float3(inversedTransform.columns[0]), simd_make_float3(inversedTransform.columns[1]), simd_make_float3(inversedTransform.columns[2]));

    [[_appCore simulation] setObserverTransform:_currrentObserverTransform];

    NSMutableArray *resources = [NSMutableArray array];
    for (int i = 0; i < cp_drawable_get_view_count(drawable); ++i) {
        CXCRendererSurface *previous = nil;
        if ([_surfaces count] > i)
            previous = [_surfaces objectAtIndex:i];
        CXCRendererSurface *renderSurface = [self createRenderPassDescriptorForDrawable:drawable index:i previousSurface:previous];

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

        if (previous == nil)
            [_surfaces addObject:renderSurface];

        [resources addObject:renderSurface];
    }

    eglWaitUntilWorkScheduledANGLE(_renderResource.eglDisplay);

    // Create a dummy commandBuffer
    id<MTLCommandBuffer> commandBuffer = [_renderResource.commandQueue commandBuffer];
    cp_drawable_encode_present(drawable, commandBuffer);
    [commandBuffer commit];

    return [resources copy];
}

- (CXCRendererSurface *)createRenderPassDescriptorForDrawable:(cp_drawable_t)drawable index:(size_t)index previousSurface:(CXCRendererSurface *)previousSurface {
    id<MTLTexture> colorTexture = cp_drawable_get_color_texture(drawable, index);
    id<MTLTexture> depthTexture = cp_drawable_get_depth_texture(drawable, index);

    GLsizei width = (GLsizei)colorTexture.width;
    GLsizei height = (GLsizei)colorTexture.height;

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
    if (previousSurface == nil) {
        glGenTextures(1, &glIntermediateColorTexture);
        glBindTexture(GL_TEXTURE_2D, glIntermediateColorTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    } else {
        glIntermediateColorTexture = previousSurface.glIntermediateColorTexture;
        if (previousSurface.width != width || previousSurface.height != height) {
            glBindTexture(GL_TEXTURE_2D, glIntermediateColorTexture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        }
    }
    glBindTexture(GL_TEXTURE_2D, 0);

    GLuint glFramebuffer;
    if (previousSurface == nil) {
        glGenFramebuffers(1, &glFramebuffer);
    } else {
        glFramebuffer = previousSurface.glFramebuffer;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, glFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, glIntermediateColorTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, glDepthTexture, 0);

    if (previousSurface == nil) {
        return [[CXCRendererSurface alloc] initWithEGLColorImage:eglColorImage eglDepthImage:eglDepthImage glColorTexture:glColorTexture glDepthTexture:glDepthTexture glIntermediateColorTexture:glIntermediateColorTexture glFramebuffer:glFramebuffer width:width height:height];
    } else {
        previousSurface.eglColorImage = eglColorImage;
        previousSurface.eglDepthImage = eglDepthImage;
        previousSurface.glColorTexture = glColorTexture;
        previousSurface.glDepthTexture = glDepthTexture;
        previousSurface.width = width;
        previousSurface.height = height;
        return previousSurface;
    }
}

@end
