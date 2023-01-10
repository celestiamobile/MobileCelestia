//
//  AsyncGLExecutor.h
//  AsyncGL
//
//  Created by Levin Li on 2023/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AsyncGLExecutor : NSObject

- (instancetype)init;

- (void)runTaskAsynchronously:(void(^)(void))task;
- (void)runTaskSynchronously:(void(NS_NOESCAPE ^)(void))task;

- (void)makeRenderContextCurrent;

@end

NS_ASSUME_NONNULL_END
