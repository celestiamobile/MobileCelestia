//
// CXCRenderer.h
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import <Foundation/Foundation.h>
#import <CompositorServices/CompositorServices.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Renderer)
@interface CXCRenderer : NSThread

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath;

- (void)startRenderingWithLayerRenderer:(cp_layer_renderer_t)layerRenderer;

@end

CXCRenderer *CXC_RendererStart(NSString *resourceFolderPath, NSString *configFilePath);

NS_ASSUME_NONNULL_END
