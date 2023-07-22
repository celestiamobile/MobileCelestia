//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import "AsyncGLView+Private.h"

#if TARGET_OS_MACCATALYST
#define TARGET_OSX_OR_CATALYST          1
#elif TARGET_OS_OSX
#define TARGET_OSX_OR_CATALYST          1
#endif

#ifdef USE_EGL
#define GL_GLEXT_PROTOTYPES
#define GL_EXT_texture_border_clamp 0
#define GL_EXT_separate_shader_objects 0
#if TARGET_OS_OSX
@import QuartzCore.CAMetalLayer;
#endif
#include <libGLESv2/libGLESv2.h>
#include <libEGL/libEGL.h>

/* EGL rendering API */
typedef enum EGLRenderingAPI : int
{
    kEGLRenderingAPIOpenGLES1 = 1,
    kEGLRenderingAPIOpenGLES2 = 2,
    kEGLRenderingAPIOpenGLES3 = 3,
} EGLRenderingAPI;

#else
#if TARGET_OSX_OR_CATALYST
@import OpenGL.GL;
@import OpenGL.GL3;
#else
@import OpenGLES.ES2;
@import OpenGLES.ES3;
#endif
#endif

#ifndef USE_EGL
#if TARGET_OSX_OR_CATALYST
@interface PassthroughGLLayer : CAOpenGLLayer
@property (nonatomic) CGLContextObj renderContext;
@property (nonatomic) CGLPixelFormatObj pixelFormat;
@property (nonatomic) GLuint sourceFramebuffer;
@property (nonatomic) GLsizei width;
@property (nonatomic) GLsizei height;
@property (atomic) NSThread *thread;
@end

@implementation PassthroughGLLayer
- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
    return _pixelFormat;
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    return _renderContext;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    return [[NSThread currentThread] isEqual:_thread];
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    CGLSetCurrentContext(ctx);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, _sourceFramebuffer);
    glBlitFramebuffer(0, 0, _width, _height, 0, 0, _width, _height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    glFlush();
}
@end
#endif
#endif

@interface AsyncGLView ()
{
    BOOL _msaaEnabled;
}

@property (nonatomic) BOOL contextsCreated;
#ifdef USE_EGL
@property (nonatomic) CAMetalLayer *metalLayer;
@property (nonatomic) EGLRenderingAPI internalAPI;
@property (nonatomic) EGLDisplay display;
@property (nonatomic) EGLSurface renderSurface;
@property (nonatomic) EGLConfig renderConfig;
@property (nonatomic) EGLContext renderContext;
#else
@property (nonatomic) GLuint framebuffer;
@property (nonatomic) GLuint depthBuffer;
@property (nonatomic) GLuint sampleFramebuffer;
@property (nonatomic) GLuint sampleDepthbuffer;
@property (nonatomic) GLuint sampleColorbuffer;
@property (nonatomic) CGSize savedBufferSize;
#if !TARGET_OSX_OR_CATALYST
@property (nonatomic) GLuint mainColorbuffer;
@property (nonatomic) EAGLRenderingAPI internalAPI;
@property (nonatomic, strong) EAGLContext *renderContext;
@property (nonatomic, strong) EAGLContext *mainContext;
#else
@property (nonatomic) GLuint renderColorbuffer;
@property (nonatomic) CGLOpenGLProfile internalAPI;
@property (nonatomic) CGLContextObj mainContext;
@property (nonatomic) CGLContextObj renderContext;
@property (nonatomic, strong) PassthroughGLLayer *glLayer;
#endif
#endif

#if TARGET_OS_IOS
@property (nonatomic) CADisplayLink *viewStateChecker;
#else
@property (nonatomic) CVDisplayLinkRef viewStateChecker;
#endif
@property (nonatomic) BOOL canRender;
@property (atomic) CGSize drawableSize;
@property (atomic) BOOL isUpdatingSize;
@property (atomic, getter=isPaused) BOOL paused;
@property (atomic) BOOL shouldRender;
@end

@implementation AsyncGLView

#if TARGET_OS_IOS
+ (Class)layerClass
{
#ifdef USE_EGL
    return [CAMetalLayer class];
#else
#if TARGET_OS_MACCATALYST
    return [PassthroughGLLayer class];
#else
    return [CAEAGLLayer class];
#endif
#endif
}
#else
- (CALayer *)makeBackingLayer
{
#ifdef USE_EGL
    return [CAMetalLayer layer];
#else
    return [PassthroughGLLayer layer];
#endif
}
#endif

#pragma mark - lifecycle/ui

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

- (void)pause
{
    [self setPaused:YES];
    [self setShouldRender:NO];
#ifndef USE_EGL
#if !TARGET_OSX_OR_CATALYST
    [self makeMainContextCurrent];
    [self flush];
#endif
#endif

    dispatch_sync(_renderQueue, ^{
        [self makeRenderContextCurrent];
        [self flush];
    });
}

- (void)resume
{
    [self setPaused:NO];

    [self _checkViewState];
}

#pragma mark - properties
- (void)setMsaaEnabled:(BOOL)msaaEnabled
{
    if (!_contextsCreated)
        _msaaEnabled = msaaEnabled;
}

- (BOOL)msaaEnabled {
    return _msaaEnabled;
}


#pragma mark - interfaces
- (void)makeRenderContextCurrent
{
#ifdef USE_EGL
    eglMakeCurrent(_display, _renderSurface, _renderSurface, _renderContext);
#else
#if !TARGET_OSX_OR_CATALYST
    [EAGLContext setCurrentContext:_renderContext];
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
#else
    CGLSetCurrentContext(_renderContext);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
#endif
#endif
}

- (void)flush
{
    glFlush();
}

- (void)clear
{
    [self clearGL];
}

- (void)render
{
    if ([self isPaused] || ![self shouldRender] || [self isUpdatingSize]) return;

    CGSize size = [self drawableSize];
    CGFloat width = size.width;
    CGFloat height = size.height;

    [self makeRenderContextCurrent];
    [self _drawGL:CGSizeMake(width, height)];
#ifdef USE_EGL
    eglSwapBuffers(_display, _renderSurface);
#else
    [self flush];
#if !TARGET_OSX_OR_CATALYST
    glBindRenderbuffer(GL_RENDERBUFFER, _mainColorbuffer);
    [_renderContext presentRenderbuffer:_mainColorbuffer];
#else
    [_glLayer setThread:[NSThread currentThread]];
    [_glLayer display];
    [_glLayer setThread:nil];
#endif
#endif
}

#pragma mark - private methods
- (void)commonSetup
{
    _drawableSize = CGSizeZero;
    _paused = YES;
    _canRender = NO;
    _shouldRender = NO;
    _contextsCreated = NO;
    _msaaEnabled = NO;
    _isUpdatingSize = NO;
#ifdef USE_EGL
    _internalAPI = _api == AsyncGLAPIOpenGLES3 ? kEGLRenderingAPIOpenGLES3 : kEGLRenderingAPIOpenGLES2;
    _display = EGL_NO_DISPLAY;
    _renderSurface = EGL_NO_SURFACE;
    _renderContext = EGL_NO_CONTEXT;
#else
#if !TARGET_OSX_OR_CATALYST
    _internalAPI = _api == AsyncGLAPIOpenGLES3 ? kEAGLRenderingAPIOpenGLES3 : kEAGLRenderingAPIOpenGLES2;
    _mainContext = nil;
    _renderContext = nil;
    _mainColorbuffer = 0;
#else
    switch (_api)
    {
    case AsyncGLAPIOpenGLCore32:
        _internalAPI = kCGLOGLPVersion_GL3_Core;
        break;
    case AsyncGLAPIOpenGLCore41:
        _internalAPI = kCGLOGLPVersion_GL4_Core;
        break;
    case AsyncGLAPIOpenGLLegacy:
    default:
        _internalAPI = kCGLOGLPVersion_Legacy;
    }
    _mainContext = NULL;
    _renderContext = NULL;
    _renderColorbuffer = 0;
#endif
    _framebuffer = 0;
    _depthBuffer = 0;
    _sampleFramebuffer = 0;
    _sampleDepthbuffer = 0;
    _sampleColorbuffer = 0;
    _savedBufferSize = CGSizeZero;
#endif

    _renderQueue = dispatch_queue_create([[[NSUUID UUID] UUIDString] UTF8String], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(_renderQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

#if TARGET_OS_OSX
    self.wantsLayer = YES;
#endif

    // Set layer properties
    self.layer.opaque = YES;
#if TARGET_OS_IOS
    self.layer.backgroundColor = [[UIColor blackColor] CGColor];
#else
    self.layer.backgroundColor = [[NSColor blackColor] CGColor];
#endif

#ifdef USE_EGL
    _metalLayer = (CAMetalLayer *)self.layer;
#else
#if TARGET_OSX_OR_CATALYST
    _glLayer = (PassthroughGLLayer *)self.layer;
    _glLayer.asynchronous = YES;
#endif
#endif
}

#pragma mark - context creation
#ifdef USE_EGL
- (EGLContext)createEGLContextWithDisplay:(EGLDisplay)display api:(EGLRenderingAPI)api sharedContext:(EGLContext)sharedContext config:(EGLConfig*)config depthSize:(EGLint)depthSize msaa:(BOOL*)msaa
{
    EGLint multisampleAttribs[] = {
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_DEPTH_SIZE, depthSize,
            EGL_SAMPLES, 4,
            EGL_SAMPLE_BUFFERS, 1,
            EGL_NONE
    };
    EGLint attribs[] = {
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_DEPTH_SIZE, depthSize,
            EGL_NONE
    };

    EGLint numConfigs;
    if (*msaa) {
        // Try to enable multisample but fallback if not available
        if (!eglChooseConfig(display, multisampleAttribs, config, 1, &numConfigs)) {
            *msaa = NO;
            NSLog(@"eglChooseConfig() returned error %d", eglGetError());
            if (!eglChooseConfig(display, attribs, config, 1, &numConfigs)) {
                NSLog(@"eglChooseConfig() returned error %d", eglGetError());
                return EGL_NO_CONTEXT;
            }
        }
    } else {
        if (!eglChooseConfig(display, attribs, config, 1, &numConfigs)) {
            NSLog(@"eglChooseConfig() returned error %d", eglGetError());
            return EGL_NO_CONTEXT;
        }
    }

    // Init context
    int ctxMajorVersion = 2;
    int ctxMinorVersion = 0;
    switch (api)
    {
        case kEGLRenderingAPIOpenGLES1:
            ctxMajorVersion = 1;
            ctxMinorVersion = 0;
            break;
        case kEGLRenderingAPIOpenGLES2:
            ctxMajorVersion = 2;
            ctxMinorVersion = 0;
            break;
        case kEGLRenderingAPIOpenGLES3:
            ctxMajorVersion = 3;
            ctxMinorVersion = 0;
            break;
        default:
            NSLog(@"Unknown GL ES API %d", api);
            return EGL_NO_CONTEXT;
    }
    EGLint ctxAttribs[] = { EGL_CONTEXT_MAJOR_VERSION, ctxMajorVersion, EGL_CONTEXT_MINOR_VERSION, ctxMinorVersion, EGL_NONE };

    EGLContext eglContext = eglCreateContext(display, *config, sharedContext, ctxAttribs);
    if (eglContext == EGL_NO_CONTEXT) {
        NSLog(@"eglCreateContext() returned error %d", eglGetError());
        return EGL_NO_CONTEXT;
    }
    return eglContext;
}
#endif

- (void)createContexts
{
#ifdef USE_EGL
    dispatch_async(_renderQueue, ^{
        [self createRenderContext];
    });
#else
#if !TARGET_OSX_OR_CATALYST
    _mainContext = [[EAGLContext alloc] initWithAPI:_internalAPI];
    if (_mainContext == nil) {
        return;
    }
    dispatch_async(_renderQueue, ^{
        [self createRenderContext];
    });
#else
    const CGLPixelFormatAttribute attr[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)_internalAPI,
        kCGLPFADoubleBuffer, 0
    };
    CGLPixelFormatObj pixelFormat = NULL;
    GLint npix;
    CGLError error = CGLChoosePixelFormat(attr, &pixelFormat, &npix);
    if (pixelFormat == NULL)
        return;
    error = CGLCreateContext(pixelFormat, NULL, &_mainContext);
    CGLReleasePixelFormat(pixelFormat);
    _glLayer.pixelFormat = pixelFormat;
    _glLayer.renderContext = _mainContext;
    if (!_mainContext) {
        return;
    }
    dispatch_async(_renderQueue, ^{
        [self createRenderContext];
    });
#endif
#endif
}

- (void)createRenderContext
{
#ifdef USE_EGL
    EGLAttrib displayAttribs[] = { EGL_NONE };
    _display = eglGetPlatformDisplay(EGL_PLATFORM_ANGLE_ANGLE, NULL, displayAttribs);
    if (_display == EGL_NO_DISPLAY) {
        NSLog(@"eglGetPlatformDisplay() returned error %d", eglGetError());
        return;
    }

    if (!eglInitialize(_display, NULL, NULL)) {
        NSLog(@"eglInitialize() returned error %d", eglGetError());
        return;
    }

    eglSwapInterval(_display, 0);

    _renderContext = [self createEGLContextWithDisplay:_display api:_internalAPI sharedContext:EGL_NO_CONTEXT config:&_renderConfig depthSize:24 msaa:&_msaaEnabled];

    if (_renderContext == EGL_NO_CONTEXT) {
        return;
    }

    _renderSurface = eglCreateWindowSurface(_display, _renderConfig, (__bridge EGLNativeWindowType)(_metalLayer), NULL);

    if (_renderSurface == EGL_NO_SURFACE) {
        NSLog(@"eglCreateWindowSurface() returned error %d", eglGetError());
        return;
    }

    __block CGSize size;
    dispatch_sync(dispatch_get_main_queue(), ^{
        size = self.frame.size;
    });
    [self makeRenderContextCurrent];
    [self setupGL:size];
#else
#if !TARGET_OSX_OR_CATALYST
    _renderContext = [[EAGLContext alloc] initWithAPI:_mainContext.API sharegroup:_mainContext.sharegroup];
    if (_renderContext == nil) {
        return;
    }
    __block CGSize size;
    dispatch_sync(dispatch_get_main_queue(), ^{
        size = self.frame.size;
        [self makeMainContextCurrent];
        [self createMainBuffers];
    });
    [self makeRenderContextCurrent];
    [self createRenderBuffers:size];
#else
    const CGLPixelFormatAttribute attr[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)_internalAPI,
        kCGLPFADepthSize, 32,
        0
    };
    const CGLPixelFormatAttribute msaaAttr[] = {
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)_internalAPI,
        kCGLPFADepthSize, 32,
        kCGLPFAMultisample,
        kCGLPFASampleBuffers, 1,
        kCGLPFASamples, 4,
        0
    };
    CGLPixelFormatObj pixelFormat = NULL;
    GLint npix;
    CGLError error = CGLChoosePixelFormat(_msaaEnabled ? msaaAttr : attr, &pixelFormat, &npix);
    if (!pixelFormat) {
        if (_msaaEnabled) {
            // Fallback to non-MSAA
            _msaaEnabled = NO;
            error = CGLChoosePixelFormat(attr, &pixelFormat, &npix);
        }
        if (!pixelFormat)
            return;
    }
    error = CGLCreateContext(pixelFormat, _mainContext, &_renderContext);
    CGLReleasePixelFormat(pixelFormat);
    if (!_renderContext) {
        return;
    }
    [self makeRenderContextCurrent];

    __block CGSize size;
    dispatch_sync(dispatch_get_main_queue(), ^{
        size = self.frame.size;
    });
    glGenRenderbuffers(1, &_renderColorbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderColorbuffer);
    [self createRenderBuffers:size];
#endif
#endif
}

#ifndef USE_EGL
#pragma mark - buffer creation
#if !TARGET_OSX_OR_CATALYST
- (void)createMainBuffers
{
    glGenRenderbuffers(1, &_mainColorbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _mainColorbuffer);
    [_mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
}
#endif

- (void)createRenderBuffers:(CGSize)size
{
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
#if TARGET_OSX_OR_CATALYST
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderColorbuffer);
#else
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _mainColorbuffer);
#endif

    if (_msaaEnabled) {
        glGenRenderbuffers(1, &_sampleColorbuffer);
        glGenRenderbuffers(1, &_sampleDepthbuffer);

        [self updateBuffersSize:size];

        glGenFramebuffers(1, &_sampleFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _sampleFramebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _sampleColorbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _sampleDepthbuffer);

        // Check sampleFramebuffer
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"framebuffer not complete %d", status);
            return;
        }

        // Bind back
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    } else {
        glGenRenderbuffers(1, &_depthBuffer);

        [self updateBuffersSize:size];

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    }

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"framebuffer not complete %d", status);
        return;
    }

    [self setupGL:size];
}

- (void)updateBuffersSize:(CGSize)size
{
    if (CGSizeEqualToSize(_savedBufferSize, size))
        return;

    _savedBufferSize = size;

    CGFloat width = size.width;
    CGFloat height = size.height;

    if (_msaaEnabled) {
        GLint samples;
        glGetIntegerv(GL_MAX_SAMPLES, &samples);

        glBindRenderbuffer(GL_RENDERBUFFER, _sampleColorbuffer);
#if !TARGET_OSX_OR_CATALYST
        glRenderbufferStorageMultisample(GL_RENDERBUFFER, samples, GL_RGBA8_OES, width, height);
#else
        glRenderbufferStorageMultisample(GL_RENDERBUFFER, samples, GL_RGBA8, width, height);
#endif

        glBindRenderbuffer(GL_RENDERBUFFER, _sampleDepthbuffer);
        glRenderbufferStorageMultisample(GL_RENDERBUFFER, samples, GL_DEPTH_COMPONENT24, width, height);
    } else {
        glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, width, height);
    }

#if TARGET_OSX_OR_CATALYST
    glBindRenderbuffer(GL_RENDERBUFFER, _renderColorbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, size.width, size.height);
    _glLayer.sourceFramebuffer = _framebuffer;
    _glLayer.width = size.width;
    _glLayer.height = size.height;
#endif
}

#if !TARGET_OSX_OR_CATALYST
- (void)makeMainContextCurrent
{
    [EAGLContext setCurrentContext:_mainContext];
}
#endif
#endif

#pragma mark - internal implementation
- (void)setupGL:(CGSize)size
{
    if ([_delegate respondsToSelector:@selector(_prepareGL:)])
    {
        BOOL prepareSuccess = [_delegate _prepareGL:size];
        if (!prepareSuccess)
        {
            [self clear];
            return;
        }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self setPaused:NO];
        [self setCanRender:YES];
        [self _startObservingViewStateNotifications];
        [self _checkViewState];
    });
}

- (void)_drawGL:(CGSize)size
{
#ifdef USE_EGL
    if ([_delegate respondsToSelector:@selector(_drawGL:)])
        [_delegate _drawGL:size];
#else
    [self updateBuffersSize:size];
    if (_msaaEnabled) {
        glBindFramebuffer(GL_FRAMEBUFFER, _sampleFramebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _sampleDepthbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _sampleColorbuffer);

#if TARGET_OS_OSX
        glEnable(GL_MULTISAMPLE);
#endif
        if ([_delegate respondsToSelector:@selector(_drawGL:)])
            [_delegate _drawGL:size];
#if TARGET_OS_OSX
        glDisable(GL_MULTISAMPLE);
#endif

        glBindFramebuffer(GL_READ_FRAMEBUFFER, _sampleFramebuffer);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _framebuffer);

#if !TARGET_OSX_OR_CATALYST
        if (_internalAPI == kEAGLRenderingAPIOpenGLES2) {
            glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_DEPTH_ATTACHMENT});
            glResolveMultisampleFramebufferAPPLE();
            glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_COLOR_ATTACHMENT0});
        } else {
            glInvalidateFramebuffer(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_DEPTH_ATTACHMENT});
            glBlitFramebuffer(0, 0, size.width, size.height, 0, 0, size.width, size.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
            glInvalidateFramebuffer(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_COLOR_ATTACHMENT0});
        }
#else
        glBlitFramebuffer(0, 0, size.width, size.height, 0, 0, size.width, size.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
#endif
    } else {
        glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
        if ([_delegate respondsToSelector:@selector(_drawGL:)])
            [_delegate _drawGL:size];
    }
#endif
}

#pragma mark - clear
- (void)clearGL
{
    [self setCanRender:NO];

#ifndef USE_EGL
    if (_depthBuffer != 0) {
        glDeleteRenderbuffers(1, &_depthBuffer);
        _depthBuffer = 0;
    }

    if (_sampleFramebuffer != 0) {
        glDeleteFramebuffers(1, &_sampleFramebuffer);
        _sampleFramebuffer = 0;
    }

    if (_sampleDepthbuffer != 0) {
        glDeleteFramebuffers(1, &_sampleDepthbuffer);
        _sampleDepthbuffer = 0;
    }

    if (_sampleColorbuffer != 0) {
        glDeleteFramebuffers(1, &_sampleColorbuffer);
        _sampleColorbuffer = 0;
    }

    if (_framebuffer != 0) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }

#if TARGET_OSX_OR_CATALYST
    if (_renderColorbuffer != 0) {
        glDeleteRenderbuffers(1, &_renderColorbuffer);
        _renderColorbuffer = 0;
    }
#endif
#endif

    [self destroyRenderContext];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self destroyMain];
    });
}

- (void)destroyMain
{
    [self _stopObservingViewStateNotifications];
#ifndef USE_EGL
#if !TARGET_OSX_OR_CATALYST
    [self makeMainContextCurrent];
    if (_mainColorbuffer != 0) {
        glDeleteRenderbuffers(1, &_mainColorbuffer);
        _mainColorbuffer = 0;
    }
#endif
    [self destroyMainContext];
#endif
}

#ifndef USE_EGL
- (void)destroyMainContext
{
#if TARGET_OSX_OR_CATALYST
    CGLReleaseContext(_mainContext);
    _mainContext = NULL;
#else
    _mainContext = nil;
#endif
}
#endif

- (void)destroyRenderContext
{
#ifdef USE_EGL
    if (_renderSurface != EGL_NO_SURFACE) {
        eglDestroySurface(_display, _renderSurface);
        _renderSurface = EGL_NO_SURFACE;
    }

    if (_renderContext != EGL_NO_CONTEXT) {
        eglMakeCurrent(_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(_display, _renderContext);
        _renderContext = EGL_NO_CONTEXT;
    }

    if (_display != EGL_NO_DISPLAY) {
        eglTerminate(_display);
        _display = EGL_NO_DISPLAY;
    }
#else
#if TARGET_OSX_OR_CATALYST
    CGLReleaseContext(_renderContext);
    _renderContext = NULL;
#else
    _renderContext = nil;
#endif
#endif
}

#pragma mark - view checker
- (void)_startObservingViewStateNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
#if TARGET_OS_OSX
    [center addObserver:self selector:@selector(_checkViewState) name:NSViewFrameDidChangeNotification object:self];
    [center addObserver:self selector:@selector(_handleWindowOcclusionStateChanged:) name:NSWindowDidChangeOcclusionStateNotification object:nil];
#else
    [center addObserver:self selector:@selector(_checkViewState) name:UIApplicationWillEnterForegroundNotification object:nil];
    [center addObserver:self selector:@selector(_checkViewState) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
}

- (void)_stopObservingViewStateNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
#if TARGET_OS_OSX
    [center removeObserver:self name:NSViewFrameDidChangeNotification object:self];
    [center removeObserver:self name:NSWindowDidChangeOcclusionStateNotification object:self];
#else
    [center removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
}

- (void)_checkViewState
{
    if ([self isPaused] || ![self canRender]) return;

    BOOL shouldRender = self.frame.size.width > 0.0f && self.frame.size.height > 0.0f && !self.isHidden && self.window;
#if TARGET_OS_IOS
    shouldRender = shouldRender && ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground);
#else
    shouldRender = shouldRender && ([[self window] occlusionState] & NSWindowOcclusionStateVisible);
#endif
    [self setShouldRender:shouldRender];

    CGFloat scale = self.layer.contentsScale;

    CGSize newSize = CGSizeMake(self.frame.size.width * scale, self.frame.size.height * scale);

    if (!CGSizeEqualToSize([self drawableSize], newSize))
    {
        [self setIsUpdatingSize:YES];
        _isUpdatingSize = YES;
#ifndef USE_EGL
#if !TARGET_OSX_OR_CATALYST
        [self makeMainContextCurrent];
        glBindRenderbuffer(GL_RENDERBUFFER, _mainColorbuffer);
        [_mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
#endif
#endif
        [self setDrawableSize:newSize];
        [self setIsUpdatingSize:NO];
    }
}

#if TARGET_OS_IOS
- (void)layoutSubviews
{
    [super layoutSubviews];

    [self _checkViewState];
}
#endif

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
#if TARGET_OS_OSX
    self.layer.contentsScale = contentScaleFactor;
#else
    [super setContentScaleFactor:contentScaleFactor];
#endif

    [self _checkViewState];
}

#if TARGET_OS_OSX
- (void)_handleWindowOcclusionStateChanged:(NSNotification *)notification
{
    if ([notification object] != [self window]) return;

    [self _checkViewState];
}
#endif

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];

    [self _checkViewState];
}

#if TARGET_OS_IOS
- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow && !_contextsCreated) {
        _contextsCreated = YES;
        [self createContexts];
    }

    [self _checkViewState];
}
#else
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];

    if (newWindow && !_contextsCreated) {
        _contextsCreated = YES;
        [self createContexts];
    }

    [self _checkViewState];
}
#endif

@end
