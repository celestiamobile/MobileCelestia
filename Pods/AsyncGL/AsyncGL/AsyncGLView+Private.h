//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import "AsyncGLAPI.h"
#import "AsyncGLView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AsyncGLViewDelegate <NSObject>

- (BOOL)_prepareGL:(CGSize)size samples:(NSInteger)samples;
- (void)_drawGL:(CGSize)size;
- (void)_clearGL;

@end

@interface AsyncGLView ()

@property (nonatomic) BOOL msaaEnabled;
@property (nonatomic) AsyncGLAPI api;
@property (nonatomic, weak) id<AsyncGLViewDelegate> delegate;

@property (nonatomic, readonly) NSThread *renderThread;

- (void)commonSetup;
- (void)requestRender;
- (void)enqueueTask:(void(^)(void))task;
- (void)render;
- (void)clear;
- (void)pause;
- (void)resume;
- (void)makeRenderContextCurrent;

@end

NS_ASSUME_NONNULL_END
