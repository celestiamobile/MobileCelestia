// CXCRenderer.m
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

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
@property (nonatomic) CGSize currentSize;

@property (nonatomic) BOOL antiAliasing;

@end

@implementation CXCRenderer

- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath extraDirectories:(NSArray<NSString *> *)extraDirectories userDefaults:(NSUserDefaults *)userDefaults appDefaultsPath:(nullable NSString *)appDefaultsPath defaultFonts:(CXCFontCollection *)defaultFonts otherFonts:(NSDictionary<NSString *, CXCFontCollection *> *)otherFonts antiAliasing:(BOOL)antiAliasing useMixedImmersion:(BOOL)useMixedImmersion {
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

        _useMixedImmersion = useMixedImmersion;
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

        _antiAliasing = antiAliasing;

        _currentSize = CGSizeZero;
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
        GLuint frameBuffer = surface.glFrameBuffer;
        glDeleteFramebuffers(1, &frameBuffer);
        GLuint renderBuffers[] = { surface.glColorRenderBuffer, surface.glDepthRenderBuffer };
        glDeleteRenderbuffers(2, renderBuffers);
        eglDestroyImageKHR(_renderResource.eglDisplay, surface.eglColorImage);
        eglDestroyImageKHR(_renderResource.eglDisplay, surface.eglDepthImage);

        if (_antiAliasing) {
            GLuint sampleFrameBuffer = surface.glSampleFrameBuffer;
            glDeleteFramebuffers(1, &sampleFrameBuffer);
            GLuint renderBuffers[] = { surface.glSampleColorRenderBuffer, surface.glSampleDepthRenderBuffer };
            glDeleteRenderbuffers(2, renderBuffers);
        }
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

    [self drawAndPresentFrame:frame drawable:drawable];

    cp_frame_end_submission(frame);
}

- (void)drawAndPresentFrame:(cp_frame_t)frame drawable:(cp_drawable_t)drawable {
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

    [_appCore setMixedImmersion:_useMixedImmersion];

    ar_device_anchor_t arPose = cp_drawable_get_device_anchor(drawable);
    simd_float4x4 poseTransform = ar_anchor_get_origin_from_anchor_transform(arPose);
    simd_float4x4 inversedTransform = simd_inverse(poseTransform);
    _currrentObserverTransform = simd_matrix(simd_make_float3(inversedTransform.columns[0]), simd_make_float3(inversedTransform.columns[1]), simd_make_float3(inversedTransform.columns[2]));

    [[_appCore simulation] setObserverQuaternion:simd_quaternion(_currrentObserverTransform)];

    EGLDisplay display = [_renderResource eglDisplay];

    size_t viewCount = cp_drawable_get_view_count(drawable);
    id<MTLCommandBuffer> commandBuffer = [[_renderResource commandQueue] commandBuffer];
    for (size_t i = 0; i < viewCount; ++i) {
        CXCRendererSurface *previous = nil;
        if ([_surfaces count] > i)
            previous = [_surfaces objectAtIndex:i];

        id<MTLTexture> colorTexture =  cp_drawable_get_color_texture(drawable, i);
        id<MTLTexture> depthTexture =  cp_drawable_get_depth_texture(drawable, i);

        id<MTLRasterizationRateMap> rateMap = [_renderResource supportsRasterizationRateMap] ? cp_drawable_get_rasterization_rate_map(drawable, i) : nil;

        CXCRendererSurface *renderSurface = [self createRenderSurface:colorTexture rasterizationRateMap:rateMap previousSurface:previous];

        cp_view_t view = cp_drawable_get_view(drawable, i);
        float left, right, top, bottom;
        simd_float2 depthRange = cp_drawable_get_depth_range(drawable);
        float nearZ = depthRange[1];
        float farZ  = depthRange[0];
        if (@available(visionOS 2, *)) {
            simd_float4x4 m = cp_drawable_compute_projection(drawable, cp_axis_direction_convention_right_up_back, i);
            left   = nearZ * (m.columns[2].x - 1.0f) / m.columns[0].x;
            right  = nearZ * (m.columns[2].x + 1.0f) / m.columns[0].x;
            bottom = nearZ * (m.columns[2].y - 1.0f) / m.columns[1].y;
            top    = nearZ * (m.columns[2].y + 1.0f) / m.columns[1].y;
        } else {
            simd_float4 tangents = cp_view_get_tangents(view);
            left = -tangents[0] * nearZ;
            right = tangents[1] * nearZ;
            top = tangents[2] * nearZ;
            bottom = -tangents[3] * nearZ;
        }

        CGSize newSize = CGSizeMake(renderSurface.screenWidth, renderSurface.screenHeight);
        if (!CGSizeEqualToSize(_currentSize, newSize))
        {
            [_appCore resize:newSize];
            _currentSize = newSize;
        }

        [_appCore setCustomPerspectiveProjectionLeft:left right:right top:top bottom:bottom nearZ:nearZ farZ:farZ];

        [_appCore setCameraTransform:simd_inverse(cp_view_get_transform(view))];

        [self preRender:renderSurface];

        [_appCore draw];

        glFlush();

        [self postRender:renderSurface];

        id<MTLEvent> sharedEvent = [renderSurface metalSharedEvent];
        uint64_t signalValue = [renderSurface signalValue];
        EGLAttrib syncAttribs[] = {
            EGL_SYNC_METAL_SHARED_EVENT_OBJECT_ANGLE,
            (EGLAttrib)sharedEvent,
            EGL_SYNC_METAL_SHARED_EVENT_SIGNAL_VALUE_HI_ANGLE,
            (EGLAttrib)(signalValue >> 32),
            EGL_SYNC_METAL_SHARED_EVENT_SIGNAL_VALUE_LO_ANGLE,
            (EGLAttrib)(signalValue & 0xFFFFFFFF),
            EGL_NONE
        };

        EGLSync sync = eglCreateSync(display, EGL_SYNC_METAL_SHARED_EVENT_ANGLE, syncAttribs);

        [commandBuffer encodeWaitForEvent:sharedEvent value:[renderSurface signalValue]];

#ifdef RENDER_USE_SHADER
        // Render the result texture using shader
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor new];

        passDescriptor.colorAttachments[0].texture = colorTexture;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

        [renderEncoder setRenderPipelineState:[_renderResource pipelineState]];

        [renderEncoder setVertexBuffer:[_renderResource vertexBuffer] offset:0 atIndex:0];

        [renderEncoder setFragmentTexture:[renderSurface metalColorTexture] atIndex:0];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];

        [renderEncoder endEncoding];

        id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        [blitEncoder copyFromTexture:renderSurface.metalDepthTexture toTexture:depthTexture];
        [blitEncoder endEncoding];
#else
        id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        [blitEncoder copyFromTexture:renderSurface.metalColorTexture toTexture:colorTexture];
        [blitEncoder copyFromTexture:renderSurface.metalDepthTexture toTexture:depthTexture];
        [blitEncoder endEncoding];
#endif

        signalValue += 1;

        [commandBuffer encodeSignalEvent:sharedEvent value:signalValue];
        renderSurface.signalValue = signalValue;

        eglDestroySync(display, sync);

        if (previous == nil)
            [_surfaces addObject:renderSurface];
    }

    cp_drawable_encode_present(drawable, commandBuffer);
    [commandBuffer commit];
}

- (void)preRender:(CXCRendererSurface *)renderSurface {
    if (_antiAliasing) {
        glBindFramebuffer(GL_FRAMEBUFFER, [renderSurface glSampleFrameBuffer]);
    } else {
        glBindFramebuffer(GL_FRAMEBUFFER, [renderSurface glFrameBuffer]);
    }
}

- (void)postRender:(CXCRendererSurface *)renderSurface {
    if (_antiAliasing) {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, [renderSurface glSampleFrameBuffer]);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, [renderSurface glFrameBuffer]);

        GLint width = (GLint)[renderSurface physicalWidth];
        GLint height = (GLint)[renderSurface physicalHeight];

        GLenum attachments[] = { GL_COLOR_ATTACHMENT0, GL_DEPTH_COMPONENT };
        glBlitFramebuffer(0, 0, width, height, 0, 0, width, height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
        glInvalidateFramebuffer(GL_READ_FRAMEBUFFER, 2, attachments);
    }
}

- (CXCRendererSurface *)createRenderSurface:(id<MTLTexture>)colorTexture rasterizationRateMap:(id<MTLRasterizationRateMap>)rasterizationRateMap previousSurface:(CXCRendererSurface *)previousSurface {
    NSUInteger physicalWidth = colorTexture.width;
    NSUInteger physicalHeight = colorTexture.height;
    NSUInteger screenWidth = physicalWidth;
    NSUInteger screenHeight = physicalHeight;
    if (rasterizationRateMap != nil) {
        MTLSize screenSize = [rasterizationRateMap screenSize];
        screenWidth = screenSize.width;
        screenHeight = screenSize.height;
    }

    const EGLint emptyAttributes[] = { EGL_NONE };

    GLuint glFrameBuffer;
    id<MTLTexture> metalColorTexture;
    id<MTLTexture> metalDepthTexture;
    EGLImageKHR eglColorImage;
    EGLImageKHR eglDepthImage;
    GLuint glColorRenderBuffer;
    GLuint glDepthRenderBuffer;
    uint64_t signalValue;
    id<MTLEvent> sharedEvent;
    GLuint glSampleColorRenderBuffer;
    GLuint glSampleDepthRenderBuffer;
    GLuint glSampleFrameBuffer;

    if (previousSurface == nil) {
        glGenFramebuffers(1, &glFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, glFrameBuffer);
        glFramebufferParameteriMESA(GL_FRAMEBUFFER, GL_FRAMEBUFFER_FLIP_Y_MESA, 1);

        if (_antiAliasing) {
            glGenFramebuffers(1, &glSampleFrameBuffer);
            glBindFramebuffer(GL_FRAMEBUFFER, glSampleFrameBuffer);
            glFramebufferParameteriMESA(GL_FRAMEBUFFER, GL_FRAMEBUFFER_FLIP_Y_MESA, 1);
        } else {
            glSampleFrameBuffer = 0;
        }

        sharedEvent = [[_renderResource device] newEvent];
        signalValue = 1;
    } else {
        sharedEvent = previousSurface.metalSharedEvent;
        uint64_t currentSignalValue = previousSurface.signalValue;
        EGLAttrib syncAttribs[] = {
            EGL_SYNC_METAL_SHARED_EVENT_OBJECT_ANGLE,
            (EGLAttrib)sharedEvent,
            EGL_SYNC_METAL_SHARED_EVENT_SIGNAL_VALUE_HI_ANGLE,
            (EGLAttrib)(currentSignalValue >> 32),
            EGL_SYNC_METAL_SHARED_EVENT_SIGNAL_VALUE_LO_ANGLE,
            (EGLAttrib)(currentSignalValue & 0xFFFFFFFF),
            EGL_SYNC_CONDITION,
            EGL_SYNC_METAL_SHARED_EVENT_SIGNALED_ANGLE,
            EGL_NONE
        };

        EGLDisplay display = [_renderResource eglDisplay];

        EGLSync sync = eglCreateSync(display, EGL_SYNC_METAL_SHARED_EVENT_ANGLE, syncAttribs);
        eglWaitSync(display, sync, 0);
        eglDestroySync(display, sync);

        glFrameBuffer = previousSurface.glFrameBuffer;
        glSampleFrameBuffer = previousSurface.glSampleFrameBuffer;

        signalValue = currentSignalValue + 1;
    }

    if (previousSurface == nil || previousSurface.physicalWidth != physicalWidth || previousSurface.physicalHeight != physicalHeight) {
        // Regenerate textures for offscreen rendering
        if (previousSurface != nil) {
            GLuint renderBuffers[] = { previousSurface.glColorRenderBuffer, previousSurface.glDepthRenderBuffer };
            glDeleteRenderbuffers(2, renderBuffers);
            eglDestroyImageKHR(_renderResource.eglDisplay, previousSurface.eglColorImage);
            eglDestroyImageKHR(_renderResource.eglDisplay, previousSurface.eglDepthImage);
        }

        id<MTLDevice> device = [_renderResource device];
        MTLTextureDescriptor *texDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:physicalWidth height:physicalHeight mipmapped:NO];
        texDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        texDescriptor.storageMode = MTLStorageModePrivate;
        metalColorTexture = [device newTextureWithDescriptor:texDescriptor];
        texDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:physicalWidth height:physicalHeight mipmapped:NO];
        texDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        texDescriptor.storageMode = MTLStorageModePrivate;
        metalDepthTexture = [device newTextureWithDescriptor:texDescriptor];

        eglColorImage = eglCreateImageKHR(_renderResource.eglDisplay, EGL_NO_CONTEXT, EGL_METAL_TEXTURE_ANGLE, (__bridge EGLClientBuffer)metalColorTexture, emptyAttributes);
        eglDepthImage = eglCreateImageKHR(_renderResource.eglDisplay, EGL_NO_CONTEXT, EGL_METAL_TEXTURE_ANGLE, (__bridge EGLClientBuffer)metalDepthTexture, emptyAttributes);

        glGenRenderbuffers(1, &glColorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, glColorRenderBuffer);
        glEGLImageTargetRenderbufferStorageOES(GL_RENDERBUFFER, eglColorImage);

        glGenRenderbuffers(1, &glDepthRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, glDepthRenderBuffer);
        glEGLImageTargetRenderbufferStorageOES(GL_RENDERBUFFER, eglDepthImage);

        if (_antiAliasing) {
            glSampleColorRenderBuffer = previousSurface.glSampleColorRenderBuffer;
            if (glSampleColorRenderBuffer == 0)
                glGenRenderbuffers(1, &glSampleColorRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, glSampleColorRenderBuffer);
            glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_RGBA8, (GLsizei)physicalWidth, (GLsizei)physicalHeight);

            glSampleDepthRenderBuffer = previousSurface.glSampleDepthRenderBuffer;
            if (glSampleDepthRenderBuffer == 0)
                glGenRenderbuffers(1, &glSampleDepthRenderBuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, glSampleDepthRenderBuffer);
            glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT24, (GLsizei)physicalWidth, (GLsizei)physicalHeight);

            glBindFramebuffer(GL_FRAMEBUFFER, glSampleFrameBuffer);

            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, glSampleColorRenderBuffer);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, glSampleDepthRenderBuffer);
        } else {
            glSampleColorRenderBuffer = 0;
            glSampleDepthRenderBuffer = 0;
        }

        glBindFramebuffer(GL_FRAMEBUFFER, glFrameBuffer);

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, glColorRenderBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, glDepthRenderBuffer);
    } else {
        eglColorImage = previousSurface.eglColorImage;
        eglDepthImage = previousSurface.eglDepthImage;
        glColorRenderBuffer = previousSurface.glColorRenderBuffer;
        glDepthRenderBuffer = previousSurface.glDepthRenderBuffer;
        glSampleColorRenderBuffer = previousSurface.glSampleColorRenderBuffer;
        glSampleDepthRenderBuffer = previousSurface.glSampleDepthRenderBuffer;
        metalColorTexture = previousSurface.metalColorTexture;
        metalDepthTexture = previousSurface.metalDepthTexture;
    }

    if ([_renderResource supportsRasterizationRateMap]) {
        if (rasterizationRateMap != nil) {
            glBindMetalRasterizationRateMapANGLE((__bridge GLMTLRasterizationRateMapANGLE)rasterizationRateMap);
            glEnable(GL_VARIABLE_RASTERIZATION_RATE_ANGLE);
        } else {
            glDisable(GL_VARIABLE_RASTERIZATION_RATE_ANGLE);
        }
    }

    if (previousSurface == nil) {
        return [[CXCRendererSurface alloc] initWithEGLColorImage: eglColorImage
                                                   eglDepthImage: eglDepthImage
                                             glColorRenderBuffer: glColorRenderBuffer
                                             glDepthRenderBuffer: glDepthRenderBuffer
                                                   glFrameBuffer: glFrameBuffer
                                       glSampleColorRenderBuffer: glSampleColorRenderBuffer
                                       glSampleDepthRenderBuffer: glSampleDepthRenderBuffer
                                             glSampleFrameBuffer: glSampleFrameBuffer
                                               metalColorTexture: metalColorTexture
                                               metalDepthTexture: metalDepthTexture
                                                     screenWidth: screenWidth
                                                    screenHeight: screenHeight
                                                   physicalWidth: physicalWidth
                                                  physicalHeight: physicalHeight
                                                metalSharedEvent: sharedEvent
                                                     signalValue: signalValue];
    } else {
        previousSurface.eglColorImage = eglColorImage;
        previousSurface.eglDepthImage = eglDepthImage;
        previousSurface.glColorRenderBuffer = glColorRenderBuffer;
        previousSurface.glDepthRenderBuffer = glDepthRenderBuffer;
        previousSurface.metalColorTexture = metalColorTexture;
        previousSurface.metalDepthTexture = metalDepthTexture;
        previousSurface.physicalWidth = physicalWidth;
        previousSurface.physicalHeight = physicalHeight;
        previousSurface.screenWidth = screenWidth;
        previousSurface.screenHeight = screenHeight;
        previousSurface.signalValue = signalValue;
        return previousSurface;
    }
}

@end
