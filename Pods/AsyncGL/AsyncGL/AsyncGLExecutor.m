//
//  AsyncGLExecutor.m
//  AsyncGL
//
//  Created by Levin Li on 2023/1/10.
//

#import "AsyncGLExecutor+Private.h"
#import "AsyncGLViewController.h"
#import "AsyncGLView+Private.h"

@implementation AsyncGLExecutor

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = nil;
        _viewController = nil;
    }
    return self;
}

- (void)runTaskAsynchronously:(void(^)(void))task {
    assert(_queue);
    dispatch_async(_queue, task);
}

- (void)runTaskSynchronously:(void(NS_NOESCAPE ^)(void))task {
    assert(_queue);
    dispatch_sync(_queue, task);
}

- (void)makeRenderContextCurrent {
    __strong AsyncGLViewController *viewController = self.viewController;
    assert(viewController != nil);
    AsyncGLView *view = [viewController glView];
    assert(view != nil);
    [view makeRenderContextCurrent];
}

@end
