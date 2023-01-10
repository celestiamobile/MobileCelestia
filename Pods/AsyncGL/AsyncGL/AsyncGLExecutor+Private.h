//
//  AsyncGLExecutor+Private.h
//  AsyncGL
//
//  Created by Levin Li on 2023/1/10.
//

#import "AsyncGLExecutor.h"

@class AsyncGLViewController;

NS_ASSUME_NONNULL_BEGIN

@interface AsyncGLExecutor ()

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, weak) AsyncGLViewController *viewController;

@end

NS_ASSUME_NONNULL_END
