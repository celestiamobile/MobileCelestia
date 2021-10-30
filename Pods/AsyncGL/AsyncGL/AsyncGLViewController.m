//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import "AsyncGLViewController.h"
#import "AsyncGLView+Private.h"

@interface AsyncGLViewController () <AsyncGLViewDelegate>

#if TARGET_OS_IOS
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) NSInteger internalPreferredFramesPerSecond;
@property (weak, nonatomic) UIScreen *internalScreen;
#else
@property (nonatomic) CVDisplayLinkRef displayLink;
#endif
@property (nonatomic) dispatch_source_t displaySource;
@property (nonatomic) BOOL msaaEnabled;
@property (nonatomic) BOOL viewIsVisible;
@property (atomic, getter=isReady) BOOL ready;

@end

@implementation AsyncGLViewController

#pragma mark - lifecycle

- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _msaaEnabled = msaaEnabled;
        _paused = YES;
#if TARGET_OS_IOS
        _pauseOnWillResignActive = YES;
        _resumeOnDidBecomeActive = YES;
        _internalPreferredFramesPerSecond = -1;
        _internalScreen = [UIScreen mainScreen];
#else
        _pauseOnWillResignActive = NO;
        _resumeOnDidBecomeActive = NO;
#endif
        _glView = nil;
        _viewIsVisible = NO;
        _ready = NO;
        [self _configureNotifications];
    }
    return self;
}

- (void)loadView
{
    _glView = [AsyncGLView new];
    _glView.msaaEnabled = _msaaEnabled;
    _glView.delegate = self;
    self.view = _glView;
}

- (void)dealloc
{
#if TARGET_OS_IOS
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
#else
    if (_displayLink) {
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
    }
#endif

    AsyncGLView *glView = _glView;
    dispatch_sync(glView.renderQueue, ^{
        [glView makeRenderContextCurrent];
        [glView flush];

        [self clearGL];
        [glView clear];
    });
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

- (void)render
{
    [_glView render];
}

- (void)requestRender
{
    dispatch_source_merge_data(_displaySource, 1);
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

#if TARGET_OS_IOS
    [_displayLink setPaused:paused];
#else
    if (_displayLink)
        paused ? CVDisplayLinkStop(_displayLink) : CVDisplayLinkStart(_displayLink);
#endif
    if ([self isReady])
        paused ? [_glView pause] : [_glView resume];
}

#pragma mark - AsyncGLViewDelegate
- (void)_prepareGL:(CGSize)size
{
    [self prepareGL:size];

    dispatch_sync(dispatch_get_main_queue(), ^{
        self.displaySource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, self.glView.renderQueue);
        __typeof__(self) __weak wself = self;
        dispatch_source_set_event_handler(self.displaySource, ^{
            __typeof__(wself) __strong sself = wself;
            [sself render];
        });
        dispatch_resume(self.displaySource);
#if TARGET_OS_IOS
        self.displayLink = [self.internalScreen displayLinkWithTarget:self selector:@selector(requestRender)];
        [self setPreferredFramesPerSecond:self.internalPreferredFramesPerSecond displayLink:self.displayLink];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
#else
        CVDisplayLinkCreateWithActiveCGDisplays(&self->_displayLink);
        CVDisplayLinkSetOutputCallback(self.displayLink, displayCallback, (__bridge void *)(self));
        CVDisplayLinkStart(self.displayLink);
#endif
    });
    [self setReady:YES];
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

- (void)prepareGL:(CGSize)rect
{
}

- (void)drawGL:(CGSize)rect
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)makeRenderContextCurrent
{
    [_glView makeRenderContextCurrent];
}

#if TARGET_OS_IOS
- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond {
    _internalPreferredFramesPerSecond = preferredFramesPerSecond;
    [self setPreferredFramesPerSecond:preferredFramesPerSecond displayLink:_displayLink];
}

- (void)setScreen:(UIScreen *)screen
{
    _internalScreen = screen;
    if (_displayLink != nil) {
        [_displayLink invalidate];
        _displayLink = [screen displayLinkWithTarget:self selector:@selector(requestRender)];
        [self setPreferredFramesPerSecond:_internalPreferredFramesPerSecond displayLink:_displayLink];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}
#endif

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

#if TARGET_OS_IOS
- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond displayLink:(CADisplayLink *)displayLink
{
    if (@available(iOS 10.0, *)) {
        if (preferredFramesPerSecond >= 0) {
            if (@available(iOS 15, *)) {
                [displayLink setPreferredFrameRateRange:CAFrameRateRangeMake(preferredFramesPerSecond / 2, preferredFramesPerSecond, preferredFramesPerSecond)];
            } else {
                [displayLink setPreferredFramesPerSecond:preferredFramesPerSecond];
            }
        } else {
            if (@available(iOS 10.3, *)) {
                CGFloat maxFramesPerSecond = [self.internalScreen maximumFramesPerSecond];
                if (@available(iOS 15, *)) {
                    [displayLink setPreferredFrameRateRange:CAFrameRateRangeMake(maxFramesPerSecond / 2, maxFramesPerSecond, maxFramesPerSecond)];
                } else {
                    [displayLink setPreferredFramesPerSecond:maxFramesPerSecond];
                }
            } else {
                [displayLink setPreferredFramesPerSecond:60];
            }
        }
    }
}
#endif

@end
