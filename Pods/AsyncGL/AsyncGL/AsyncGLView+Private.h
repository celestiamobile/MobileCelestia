//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import "AsyncGLAPI.h"
#import "AsyncGLView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AsyncGLViewDelegate <NSObject>

- (BOOL)_prepareGL:(CGSize)size;
- (void)_drawGL:(CGSize)size;

@end

@interface AsyncGLView ()

@property (nonatomic) BOOL msaaEnabled;
@property (nonatomic) AsyncGLAPI api;
@property (nonatomic, weak) id<AsyncGLViewDelegate> delegate;

- (void)commonSetup;
- (void)render;
- (void)clear;
- (void)flush;
- (void)pause;
- (void)resume;
- (void)makeRenderContextCurrent;

@end

NS_ASSUME_NONNULL_END
