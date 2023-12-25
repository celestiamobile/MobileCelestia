//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import <AsyncGL/AsyncGLAPI.h>

@class AsyncGLExecutor;

#if TARGET_OS_IOS
@import UIKit;
#else
@import Cocoa;
#endif

@class AsyncGLView;

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS
@interface AsyncGLViewController : UIViewController
#else
@interface AsyncGLViewController : NSViewController
#endif

@property (nonatomic) BOOL pauseOnWillResignActive;
@property (nonatomic) BOOL resumeOnDidBecomeActive;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic, nullable) AsyncGLView *glView;

#if TARGET_OS_IOS
- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled screen:(nullable UIScreen *)screen initialFrameRate:(NSInteger)frameRate api:(AsyncGLAPI)api executor:(AsyncGLExecutor *)executor NS_DESIGNATED_INITIALIZER;
#else
- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled screen:(nullable NSScreen *)screen initialFrameRate:(NSInteger)frameRate api:(AsyncGLAPI)api executor:(AsyncGLExecutor *)executor NS_DESIGNATED_INITIALIZER;
#endif
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (BOOL)prepareGL:(CGSize)size;
- (void)drawGL:(CGSize)size;
- (void)clearGL;

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond API_AVAILABLE(ios(10.0), tvos(10.0), macos(14.0));
#if TARGET_OS_IOS
- (void)setScreen:(nullable UIScreen *)screen;
#else
- (void)setScreen:(nullable NSScreen *)screen;
#endif

@end

NS_ASSUME_NONNULL_END
