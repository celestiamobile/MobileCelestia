//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import "AsyncGLViewController.h"
#import "AsyncGLView+Private.h"
#import "AsyncGLExecutor+Private.h"

#if !TARGET_OS_IOS
@import QuartzCore;
#endif

@interface AsyncGLViewController () <AsyncGLViewDelegate>

@property (nonatomic) AsyncGLExecutor *internalExecutor;

@property (nonatomic) NSInteger internalPreferredFramesPerSecond;
#if TARGET_OS_IOS
@property (nonatomic) CADisplayLink *displayLink;
@property (weak, nonatomic) UIScreen *internalScreen;
#else
@property (nonatomic) CVDisplayLinkRef cvDisplayLink;
@property (nonatomic) CADisplayLink *displayLink API_AVAILABLE(macos(14.0));
@property (weak, nonatomic) NSScreen *internalScreen;
#endif
@property (nonatomic) dispatch_source_t displaySource;
@property (nonatomic) BOOL msaaEnabled;
@property (nonatomic) BOOL viewIsVisible;
@property (atomic, getter=isReady) BOOL ready;
@property (nonatomic) AsyncGLAPI api;
@end

@implementation AsyncGLViewController

#pragma mark - lifecycle

#if TARGET_OS_IOS
- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled screen:(UIScreen *)screen initialFrameRate:(NSInteger)frameRate api:(AsyncGLAPI)api executor:(AsyncGLExecutor *)executor
#else
- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled screen:(NSScreen *)screen initialFrameRate:(NSInteger)frameRate api:(AsyncGLAPI)api executor:(AsyncGLExecutor *)executor
#endif
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _msaaEnabled = msaaEnabled;
        _paused = YES;
        _internalScreen = screen;
        _internalPreferredFramesPerSecond = frameRate;
        _displayLink = nil;
#if TARGET_OS_IOS
        _pauseOnWillResignActive = YES;
        _resumeOnDidBecomeActive = YES;
#else
        _pauseOnWillResignActive = NO;
        _resumeOnDidBecomeActive = NO;
        _cvDisplayLink = NULL;
#endif
        _glView = nil;
        _viewIsVisible = NO;
        _ready = NO;
        _internalExecutor = executor;
        _api = api;
        [self _configureNotifications];
    }
    return self;
}

- (void)loadView
{
    _glView = [AsyncGLView new];
    _glView.api = _api;
    _glView.msaaEnabled = _msaaEnabled;
    [_glView commonSetup];
    _glView.delegate = self;
    self.view = _glView;
    _internalExecutor.view = _glView;
}

- (void)dealloc
{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }

#if !TARGET_OS_IOS
    if (_cvDisplayLink != NULL) {
        CVDisplayLinkStop(_cvDisplayLink);
        CVDisplayLinkRelease(_cvDisplayLink);
        _cvDisplayLink = NULL;
    }
#endif

    [_glView clear];
}

#if TARGET_OS_IOS
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    _viewIsVisible = NO;
    [self setPaused:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _viewIsVisible = YES;
    [self setPaused:NO];
}

#else
- (void)viewWillDisappear
{
    [super viewWillDisappear];

    _viewIsVisible = NO;
    [self setPaused:YES];
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    _viewIsVisible = YES;
    [self setPaused:NO];
}
#endif

#pragma mark - private methods

- (void)requestRender
{
    [_glView requestRender];
}

#if TARGET_OS_OSX
static CVReturn displayCallback(CVDisplayLinkRef displayLink,
    const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime,
    CVOptionFlags flagsIn, CVOptionFlags *flagsOut,
    void *displayLinkContext)
{
    AsyncGLViewController *vc = (__bridge AsyncGLViewController *)displayLinkContext;
    [vc requestRender];
    return kCVReturnSuccess;
}
#endif

#pragma mark - getters/setters

- (void)setPaused:(BOOL)paused
{
    _paused = paused;

    if (_displayLink != nil)
        [_displayLink setPaused:paused];
#if !TARGET_OS_IOS
    else if (_cvDisplayLink != NULL)
        paused ? CVDisplayLinkStop(_cvDisplayLink) : CVDisplayLinkStart(_cvDisplayLink);
#endif

    if ([self isReady])
        paused ? [_glView pause] : [_glView resume];
}

#pragma mark - AsyncGLViewDelegate
- (BOOL)_prepareGL:(CGSize)size
{
    if (![self prepareGL:size])
        return NO;

    dispatch_sync(dispatch_get_main_queue(), ^{
#if !TARGET_OS_IOS
        if (@available(macOS 14.0, *)) {
#endif
            self.displayLink = [self.internalScreen displayLinkWithTarget:self selector:@selector(requestRender)];
            if (self.displayLink == nil) {
#if TARGET_OS_IOS
                self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(requestRender)];
#else
                self.displayLink = [self.view displayLinkWithTarget:self selector:@selector(requestRender)];
#endif
            }
            [self setPreferredFramesPerSecond:self.internalPreferredFramesPerSecond displayLink:self.displayLink];
            [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
#if !TARGET_OS_IOS
        } else {
            NSNumber *directDisplayIDNumber = self.internalScreen.deviceDescription[@"NSScreenNumber"];
            if (directDisplayIDNumber != nil)
                CVDisplayLinkCreateWithCGDisplay((CGDirectDisplayID)[directDisplayIDNumber unsignedIntValue], &self->_cvDisplayLink);
            else
                CVDisplayLinkCreateWithActiveCGDisplays(&self->_cvDisplayLink);
            CVDisplayLinkSetOutputCallback(self.cvDisplayLink, displayCallback, (__bridge void *)(self));
            CVDisplayLinkStart(self.cvDisplayLink);
        }
#endif
    });
    [self setReady:YES];
    return YES;
}

- (void)_drawGL:(CGSize)size
{
    [self drawGL:size];
}

- (void)_clearGL
{
    [self clearGL];
}

- (void)clearGL
{
}

- (BOOL)prepareGL:(CGSize)rect
{
    return YES;
}

- (void)drawGL:(CGSize)rect
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond {
    _internalPreferredFramesPerSecond = preferredFramesPerSecond;
    [self setPreferredFramesPerSecond:preferredFramesPerSecond displayLink:_displayLink];
}

#if TARGET_OS_IOS
- (void)setScreen:(UIScreen *)screen
#else
- (void)setScreen:(NSScreen *)screen
#endif
{
    _internalScreen = screen;
#if !TARGET_OS_IOS
    if (@available(macOS 14.0, *)) {
#endif
        if (_displayLink != nil) {
            [_displayLink invalidate];
            _displayLink = nil;
        }

        _displayLink = [screen displayLinkWithTarget:self selector:@selector(requestRender)];
        if (_displayLink == nil) {
#if TARGET_OS_IOS
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(requestRender)];
#else
            _displayLink = [self.view displayLinkWithTarget:self selector:@selector(requestRender)];
#endif
        }
        [self setPreferredFramesPerSecond:_internalPreferredFramesPerSecond displayLink:_displayLink];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
#if !TARGET_OS_IOS
    } else {
        if (_cvDisplayLink != NULL) {
            CVDisplayLinkStop(_cvDisplayLink);
            CVDisplayLinkRelease(_cvDisplayLink);
            _cvDisplayLink = NULL;
        }

        NSNumber *directDisplayIDNumber = screen.deviceDescription[@"NSScreenNumber"];
        if (directDisplayIDNumber != nil)
            CVDisplayLinkCreateWithCGDisplay((CGDirectDisplayID)[directDisplayIDNumber unsignedIntValue], &self->_cvDisplayLink);
        else
            CVDisplayLinkCreateWithActiveCGDisplays(&self->_cvDisplayLink);
        CVDisplayLinkSetOutputCallback(self.cvDisplayLink, displayCallback, (__bridge void *)(self));
        CVDisplayLinkStart(self.cvDisplayLink);
    }
#endif
}

#pragma mark - private methods
- (void)_configureNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

#if TARGET_OS_IOS
    [center addObserver:self selector:@selector(_pauseByNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(_resumeByNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
#else
    [center addObserver:self selector:@selector(_pauseByNotification) name:NSApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(_resumeByNotification) name:NSApplicationDidBecomeActiveNotification object:nil];
#endif

}

- (void)_pauseByNotification
{
    if (_pauseOnWillResignActive)
        [self setPaused:YES];
}

- (void)_resumeByNotification
{
    if (_resumeOnDidBecomeActive && _viewIsVisible)
        [self setPaused:NO];
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond displayLink:(CADisplayLink *)displayLink API_AVAILABLE(ios(10.0), tvos(10.0), macos(14.0)) {
    if (preferredFramesPerSecond >= 0) {
#if TARGET_OS_IOS
        if (@available(iOS 15, *)) {
#endif
            [displayLink setPreferredFrameRateRange:CAFrameRateRangeMake(preferredFramesPerSecond / 2, preferredFramesPerSecond, preferredFramesPerSecond)];
#if TARGET_OS_IOS
        } else {
            [displayLink setPreferredFramesPerSecond:preferredFramesPerSecond];
        }
#endif
    } else {
#if TARGET_OS_IOS
        if (@available(iOS 10.3, *)) {
#endif
            CGFloat maxFramesPerSecond = [self.internalScreen maximumFramesPerSecond];
#if TARGET_OS_IOS
            if (@available(iOS 15, *)) {
#endif
                [displayLink setPreferredFrameRateRange:CAFrameRateRangeMake(maxFramesPerSecond / 2, maxFramesPerSecond, maxFramesPerSecond)];
#if TARGET_OS_IOS
            } else {
                [displayLink setPreferredFramesPerSecond:maxFramesPerSecond];
            }
        } else {
            [displayLink setPreferredFramesPerSecond:60];
        }
#endif
    }
}

@end
