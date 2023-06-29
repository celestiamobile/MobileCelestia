// CXCRenderer.h
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#import <Foundation/Foundation.h>
#import <CompositorServices/CompositorServices.h>
#import <Spatial/Spatial.h>

NS_ASSUME_NONNULL_BEGIN

@class CXCFontCollection;
@class CXCInputEvent;
@class CelestiaAppCore;
@class CelestiaAppState;

NS_SWIFT_SENDABLE
typedef NS_ENUM(NSUInteger, CXCRendererStatus) {
    CXCRendererStatusNone,
    CXCRendererStatusLoading,
    CXCRendererStatusLoaded,
    CXCRendererStatusRendering,
    CXCRendererStatusInvalidated,
    CXCRendererStatusFailed,
} NS_SWIFT_NAME(RendererStatus);

NS_SWIFT_NAME(Renderer)
@interface CXCRenderer : NSObject

@property (readonly, nonatomic) CXCRendererStatus status;
@property (nonatomic) BOOL useMixedImmersion;
@property (nullable, nonatomic) void (NS_SWIFT_SENDABLE ^stateUpdater)(CelestiaAppState *);
@property (nullable, nonatomic) void (NS_SWIFT_SENDABLE ^statusUpdater)(CXCRendererStatus);
@property (nullable, nonatomic) void (NS_SWIFT_SENDABLE ^fileNameUpdater)(NSString *);
@property (nullable, nonatomic) void (NS_SWIFT_SENDABLE ^messageUpdater)(NSString *);

@property (readonly, nonatomic) CelestiaAppCore *appCore;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResourceFolderPath:(NSString *)resourceFolderPath configFilePath:(NSString *)configFilePath extraDirectories:(NSArray<NSString *> *)extraDirectories userDefaults:(NSUserDefaults *)userDefaults appDefaultsPath:(nullable NSString *)appDefaultsPath defaultFonts:(CXCFontCollection *)defaultFonts otherFonts:(NSDictionary<NSString *, CXCFontCollection *> *)otherFonts antiAliasing:(BOOL)antiAliasing useMixedImmersion:(BOOL)useMixedImmersion;

- (void)enqueueTask:(void (NS_SWIFT_SENDABLE ^)(CelestiaAppCore *))task;
- (void)enqueueEvents:(NSArray<CXCInputEvent *> *)events;
- (void)prepare;
- (void)startRenderingWithLayerRenderer:(cp_layer_renderer_t)layerRenderer;

@end

NS_ASSUME_NONNULL_END
