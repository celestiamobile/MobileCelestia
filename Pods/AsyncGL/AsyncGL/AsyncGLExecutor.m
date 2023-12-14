//
//  AsyncGLExecutor.m
//  AsyncGL
//
//  Created by Levin Li on 2023/1/10.
//

#import "AsyncGLExecutor+Private.h"
#import "AsyncGLView+Private.h"

@implementation AsyncGLExecutor

- (instancetype)init {
    self = [super init];
    if (self)
        _view = nil;
    return self;
}

- (void)runTaskAsynchronously:(void(^)(void))task {
    assert(_view != nil);
    [_view enqueueTask:task];
}

- (void)runTaskSynchronously:(void(^)(void))task {
    assert(_view != nil);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [_view enqueueTask:^{
        task();
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)makeRenderContextCurrent {
    assert(_view != nil);
    [_view makeRenderContextCurrent];
}

@end
