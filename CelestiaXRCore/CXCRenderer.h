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
#import <CelestiaCore/CelestiaCore.h>
#import <CompositorServices/CompositorServices.h>
#import <Spatial/Spatial.h>

NS_ASSUME_NONNULL_BEGIN

@class CXCFontCollection;
@class CXCInputEvent;

typedef NS_ENUM(NSUInteger, CXCRendererStatus) {
    CXCRendererStatusNone,
    CXCRendererStatusLoading,
    CXCRendererStatusLoaded,
    CXCRendererStatusRendering,
    CXCRendererStatusInvalidated,
} NS_SWIFT_NAME(RendererStatus);

NS_SWIFT_NAME(Renderer)
@interface CXCRenderer : NSObject

@property (readonly) CXCRendererStatus status;
@property (nullable) void (^selectionUpdater)(CelestiaSelection *);
@property (nullable) void (^statusUpdater)(CXCRendererStatus);
@property (nullable) void (^fileNameUpdater)(NSString *);
@property (nullable) void (^messageUpdater)(NSString *);

@property (readonly) CelestiaAppCore *appCore;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath userDefaultsPath:(nullable NSString *)userDefaultsPath defaultFonts:(CXCFontCollection *)defaultFonts otherFonts:(NSDictionary<NSString *, CXCFontCollection *> *)otherFonts;
- (instancetype)initRenderer:(CXCRenderer *)renderer;

- (void)enqueueTask:(void (^)(CelestiaAppCore *))task;
- (void)enqueueEvents:(NSArray<CXCInputEvent *> *)events;
- (void)prepare;
- (void)startRenderingWithLayerRenderer:(cp_layer_renderer_t)layerRenderer;

@end

NS_ASSUME_NONNULL_END
