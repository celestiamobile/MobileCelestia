//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import "AsyncGLView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AsyncGLViewDelegate <NSObject>

- (void)_prepareGL:(CGSize)size;
- (void)_drawGL:(CGSize)size;

@end

@interface AsyncGLView ()

@property (nonatomic) BOOL msaaEnabled;
@property (nonatomic, weak) id<AsyncGLViewDelegate> delegate;

- (void)render;
- (void)clear;
- (void)flush;
- (void)pause;
- (void)resume;
- (void)makeRenderContextCurrent;

@end

NS_ASSUME_NONNULL_END
