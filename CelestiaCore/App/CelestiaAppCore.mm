// CelestiaAppCore.mm
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.


#include <celmath/frustum.h>
#include <celengine/body.h>
#include <celengine/glsupport.h>

#import "CelestiaAppCore+Private.h"
#import "CelestiaAppCore+Setting.h"
#import "CelestiaAppState+Private.h"
#import "CelestiaSimulation+Private.h"

#import "CelestiaSelection+Private.h"
#import "CelestiaDestination+Private.h"

#import "CelestiaUtil.h"

#include <celutil/gettext.h>
#include <celutil/localeutil.h>
#include <celestia/configfile.h>
#include <celestia/progressnotifier.h>
#include <celestia/url.h>
#include <celengine/perspectiveprojectionmode.h>
#include <celengine/shadermanager.h>

#include <unicode/uloc.h>

#include <memory>

using namespace Eigen;

class CustomPerspectiveProjectionMode : public celestia::engine::PerspectiveProjectionMode
{
public:
    CustomPerspectiveProjectionMode(float left, float right, float top, float bottom, float nearZ, float farZ, float width, float height) : PerspectiveProjectionMode(width, height, 0, 0), left(left), right(right), top(top), bottom(bottom), nearZ(nearZ), farZ(std::isinf(farZ) ? maximumFarZ : std::min(farZ, maximumFarZ))
    {
    }

    CustomPerspectiveProjectionMode(const CustomPerspectiveProjectionMode &) = default;
    CustomPerspectiveProjectionMode(CustomPerspectiveProjectionMode &&) = default;
    CustomPerspectiveProjectionMode &operator=(const CustomPerspectiveProjectionMode &) = default;
    CustomPerspectiveProjectionMode &operator=(CustomPerspectiveProjectionMode &&) = default;
    ~CustomPerspectiveProjectionMode() = default;

    std::tuple<float, float> getDefaultDepthRange() const override
    {
        return std::make_tuple(nearZ, farZ);
    }

    Matrix4f getProjectionMatrix(float nz, float fz, float) const override
    {
        float ratio = nz / nearZ;

        float l = ratio * left;
        float r = ratio * right;
        float t = ratio * top;
        float b = ratio * bottom;

        // https://registry.khronos.org/OpenGL-Refpages/gl2.1/xhtml/glFrustum.xml
        float A = (r + l) / (r - l);
        float B = (t + b) / (t - b);
        float C = -(fz + nz) / (fz - nz);
        float D = -2.0f * fz * nz / (fz - nz);

        Matrix4f m;

        m << 2.0f * nz / (r - l),                0.0f,     A, 0.0f,
             0.0f,                2.0f * nz / (t - b),     B, 0.0f,
             0.0f,                               0.0f,     C,    D,
             0.0f,                               0.0f, -1.0f, 0.0f;

        return m;
    }

    float getMinimumFOV() const override { return getFOV(1.0f); };
    float getMaximumFOV() const override { return getFOV(1.0f); };
    float getFOV(float zoom) const override
    {
        float a = top * top + nearZ * nearZ;
        float b = bottom * bottom + nearZ * nearZ;
        float c = (top - bottom) * (top - bottom);
        return std::acos((a + b - c) / (2.0f * std::sqrt(a * b)));
    }
    float getZoom(float fov) const override { return 1.0f; }
    celestia::math::Frustum getFrustum(float _nearZ, float _farZ, float zoom) const override {
        float ratio = _nearZ / nearZ;
        return celestia::math::Frustum(left * ratio, right * ratio, top * ratio, bottom * ratio, _nearZ, _farZ);
    }
    double getViewConeAngleMax(float zoom) const override
    {
        float a = left * left + top * top;
        float b = right * right + top * top;
        float c = left * left + bottom * bottom;
        float d = right * right + bottom * bottom;
        float maxValue = std::max({a, b, c, d});
        return static_cast<double>(nearZ) / std::sqrt(static_cast<double>(nearZ * nearZ + maxValue));
    }

    static constexpr float maximumFarZ = 1.0e9f;

    Vector3f getPickRay(float x, float y, float zoom) const override
    {
        auto invProj = getProjectionMatrix(nearZ, maximumFarZ, 1.0f).inverse();
        float aspectRatio = width / height;
        Vector4f clip(x / aspectRatio * 2.0f, y * 2.0f, -1.0, 1.0);
        return (invProj * clip).head<3>().normalized();
    }

    Vector2f getRayIntersection(Vector3f pickRay, float zoom) const override
    {
        auto proj = getProjectionMatrix(nearZ, maximumFarZ, 1.0f);
        float coeff = -nearZ / pickRay.z();
        Vector4f point(coeff * pickRay.x(), coeff * pickRay.y(), -nearZ, 1.0f);
        Vector4f projected = proj * point;
        projected /= projected.w();
        float aspectRatio = width / height;
        return Vector2f(projected.x() * aspectRatio, projected.y());
    }

private:
    float left;
    float right;
    float bottom;
    float top;
    float nearZ;
    float farZ;
};

class AppCoreProgressWatcher: public ProgressNotifier
{
public:
    AppCoreProgressWatcher(void (^block)(NSString *)) : ProgressNotifier(), block(block) {};

    void update(const std::string& status) override {
        @autoreleasepool {
            block([NSString stringWithUTF8String:status.c_str()]);
        }
    }
private:
    void (^block)(NSString *);
};

class AppCoreAlerter: public CelestiaCore::Alerter
{
public:
    AppCoreAlerter(void (^block)(NSString *)) : CelestiaCore::Alerter(), block(block) {};

    void fatalError(const std::string &error)
    {
        @autoreleasepool {
            block([NSString stringWithUTF8String:error.c_str()]);
        }
    }
private:
    void (^block)(NSString *);
};

class AppCoreCursorHandler: public CelestiaCore::CursorHandler
{
public:
    AppCoreCursorHandler(void (^block)(CelestiaCursorShape)) : CelestiaCore::CursorHandler(), block(block), shape(CelestiaCore::ArrowCursor) {};

    void setCursorShape(CelestiaCore::CursorShape shape)
    {
        CelestiaCore::CursorShape oldShape = this->shape;
        if (oldShape != shape)
        {
            this->shape = shape;
            @autoreleasepool {
                block(static_cast<CelestiaCursorShape>(shape));
            }
        }
    }

    CelestiaCore::CursorShape getCursorShape() const
    {
        return shape;
    }
private:
    void (^block)(CelestiaCursorShape);
    CelestiaCore::CursorShape shape;
};

class AppCoreContextMenuHandler: public CelestiaCore::ContextMenuHandler
{
public:
    AppCoreContextMenuHandler(void (^block)(CGPoint, CelestiaSelection *)) : CelestiaCore::ContextMenuHandler(), block(block) {};

    void requestContextMenu(float x, float y, Selection sel) override
    {
        @autoreleasepool {
            CelestiaSelection *selection = [[CelestiaSelection alloc] initWithSelection:sel];
            block(CGPointMake(x, y), selection);
        }
    }
private:
    void (^block)(CGPoint, CelestiaSelection *);
};

@interface CelestiaAppCore () {
    std::unique_ptr<AppCoreAlerter> alerter;
    std::unique_ptr<AppCoreCursorHandler> cursorHandler;
    std::unique_ptr<AppCoreContextMenuHandler> internalContextMenuHandler;

    CelestiaSimulation *_simulation;
}

@end

@implementation CelestiaAppCore

// MARK: Initilalization
- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _initialized = NO;
        _simulation = nil;
        core = new CelestiaCore;
        __weak CelestiaAppCore *weakSelf = self;
        alerter = std::make_unique<AppCoreAlerter>(^(NSString *error) {
            [[weakSelf delegate] celestiaAppCoreFatalErrorHappened:error];
        });
        cursorHandler = std::make_unique<AppCoreCursorHandler>(^(CelestiaCursorShape shape) {
            [[weakSelf delegate] celestiaAppCoreCursorShapeChanged:shape];
        });
        internalContextMenuHandler = std::make_unique<AppCoreContextMenuHandler>(^(CGPoint location, CelestiaSelection *selection) {
            __strong CelestiaAppCore *core = weakSelf;
            if (core != nil) {
                __strong id<CelestiaAppCoreContextMenuHandler> contextMenuHandler = core.contextMenuHandler;
                if (contextMenuHandler) {
                    [contextMenuHandler celestiaAppCoreCursorDidRequestContextMenuAtPoint:location withSelection:selection];
                }
            }
        });
        core->setAlerter(alerter.get());
        core->setCursorHandler(cursorHandler.get());
        core->setContextMenuHandler(internalContextMenuHandler.get());

        CelestiaCore::ScriptSystemAccessPolicy (^scriptSystemAccessHandler)(void) = ^{
            __strong CelestiaAppCore *core = weakSelf;
            if (core == nil) { return CelestiaCore::ScriptSystemAccessPolicy::Ask; }
            __strong id<CelestiaAppCoreDelegate> delegate = [core delegate];
            if (delegate == nil) { return CelestiaCore::ScriptSystemAccessPolicy::Ask; }

            return [delegate celestiaAppCoreRequestSystemAccess] ? CelestiaCore::ScriptSystemAccessPolicy::Allow : CelestiaCore::ScriptSystemAccessPolicy::Deny;
        };
        core->setScriptSystemAccessHandler([scriptSystemAccessHandler]{
            @autoreleasepool {
                return scriptSystemAccessHandler();
            }
        });
    }
    return self;
}

+ (BOOL)initGL {
    return static_cast<BOOL>(celestia::gl::init());
}

- (BOOL)startSimulationWithConfigFileName:(NSString *)configFileName extraDirectories:(NSArray<NSString *> *)extraDirectories progressReporter:(void (NS_NOESCAPE ^)(NSString *))reporter {

    AppCoreProgressWatcher watcher(reporter);

    std::string configFile = configFileName == nil ? "" : [configFileName UTF8String];
    __block std::vector<std::filesystem::path> extras;
    [extraDirectories enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        extras.emplace_back([obj UTF8String]);
    }];

    bool success = core->initSimulation(configFile, extras, &watcher);
    if (success) {
        _initialized = YES;
    }
    return _initialized;
}

- (BOOL)startRendererWithSRGBRendering:(BOOL)srgbRendering shadowMapSize:(NSInteger)shadowMapSize {
    BOOL success = core->initRenderer(celestia::engine::TextureResolution::medres, static_cast<bool>(srgbRendering)) ? YES : NO;

    // start with default values
    constexpr auto DEFAULT_ORBIT_MASK = BodyClassification::Planet | BodyClassification::Moon | BodyClassification::Stellar;
    constexpr auto DEFAULT_LABEL_MODE = RenderLabels::I18nConstellationLabels | RenderLabels::LocationLabels;
    constexpr float DEFAULT_AMBIENT_LIGHT_LEVEL = 0.1f;
    constexpr float DEFAULT_VISUAL_MAGNITUDE = 8.0f;
    constexpr StarStyle DEFAULT_STAR_STYLE = StarStyle::FuzzyPointStars;
    constexpr ColorTableType DEFAULT_STARS_COLOR = ColorTableType::SunWhite;
    constexpr float DEFAULT_TINT_SATURATION = 0.5f;

    core->getRenderer()->setRenderFlags(RenderFlags::DefaultRenderFlags);
    core->getRenderer()->setOrbitMask(DEFAULT_ORBIT_MASK);
    core->getRenderer()->setLabelMode(DEFAULT_LABEL_MODE);
    core->getRenderer()->setAmbientLightLevel(DEFAULT_AMBIENT_LIGHT_LEVEL);
    core->getRenderer()->setTintSaturation(DEFAULT_TINT_SATURATION);
    core->getRenderer()->setStarStyle(DEFAULT_STAR_STYLE);
    core->getRenderer()->setStarColorTable(DEFAULT_STARS_COLOR);

    core->getSimulation()->setFaintestVisible(DEFAULT_VISUAL_MAGNITUDE);

    core->getRenderer()->setSolarSystemMaxDistance((core->getConfig()->renderDetails.SolarSystemMaxDistance));
    core->getRenderer()->setShadowMapSize(static_cast<unsigned>(shadowMapSize));

    return success;
}

- (NSInteger)screenDPI {
    return static_cast<NSInteger>(core->getScreenDpi());
}

- (void)setScreenDPI:(NSInteger)screenDPI {
    core->setScreenDpi(static_cast<int>(screenDPI));
}

- (CGFloat)textScaleFactor {
    return static_cast<CGFloat>(core->getTextScaleFactor());
}

- (void)setTextScaleFactor:(CGFloat)textScaleFactor {
    core->setTextScaleFactor(static_cast<float>(textScaleFactor));
}

- (void)setStartURL:(NSString *)startURL {
    if (!startURL)
        core->setStartURL("");
    else
        core->setStartURL([startURL UTF8String]);
}

- (void)start {
    core->start();
}

- (void)start:(NSDate *)date {
    core->start([date julianDay]);
}

// MARK: Drawing

- (void)draw {
    core->draw();
}

- (void)tick {
    core->tick();
}

- (void)tick:(NSTimeInterval)elapsedTime {
    core->tick(elapsedTime);
}

+ (void)finish {
    glFinish();
}

- (CGSize)size {
    auto [width, height] = core->getWindowDimension();
    return CGSizeMake(static_cast<CGFloat>(width), static_cast<CGFloat>(height));
}

- (void)resize:(CGSize)size {
    core->resize(size.width, size.height);
}

- (void)setPhysicalSize:(CGSize)size {
    core->setPhysicalSize(static_cast<int>(size.width), static_cast<int>(size.height));
}

- (void)setSafeAreaInsetsWithLeft:(CGFloat)left top:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom {
    core->setSafeAreaInsets(left, top, right, bottom);
}

- (void)setHudFont:(NSString *)fontPath collectionIndex:(NSInteger)collectionIndex fontSize:(NSInteger)fontSize {
    core->setHudFont([fontPath UTF8String], collectionIndex, fontSize);
}

- (void)setHudTitleFont:(NSString *)fontPath collectionIndex:(NSInteger)collectionIndex fontSize:(NSInteger)fontSize {
    core->setHudTitleFont([fontPath UTF8String], collectionIndex, fontSize);
}

- (void)setRendererFont:(NSString *)fontPath collectionIndex:(NSInteger)collectionIndex fontSize:(NSInteger)fontSize fontStyle:(CelestiaRendererFontStyle)fontStyle {
    core->setRendererFont([fontPath UTF8String], collectionIndex, fontSize, static_cast<Renderer::FontStyle>(fontStyle));
}

- (void)setPickTolerance:(CGFloat)pickTolerance {
    core->setPickTolerance(pickTolerance);
}

// MARK: Other
- (NSString *)currentURL {
    CelestiaState appState(core);
    appState.captureState();

    Url currentURL(appState, Url::CurrentVersion);
    return [NSString stringWithUTF8String:currentURL.getAsString().c_str()];
}

- (NSArray<CelestiaDestination *> *)destinations {
    NSMutableArray *array = [NSMutableArray array];
    auto destinations = core->getDestinations();
    int count = destinations ? destinations->size() : 0;
    for (int i = 0; i < count; ++i)
        [array addObject:[[CelestiaDestination alloc] initWithDestination:destinations->at(i)]];
    return [array copy];
}

- (CelestiaTextEnterMode)textEnterMode {
    return static_cast<CelestiaTextEnterMode>(core->getTextEnterMode());
}

- (void)setTextEnterMode:(CelestiaTextEnterMode)textEnterMode {
    core->setTextEnterMode(static_cast<celestia::Hud::TextEnterMode>(textEnterMode));
}

- (void)runScript:(NSString *)path {
    core->runScript([path UTF8String], false);
}

- (void)cancelScript {
    core->cancelScript();
}

- (void)goToURL:(NSString *)url {
    core->goToUrl([url UTF8String]);
}

- (BOOL)screenshot:(NSString *)filePath withFileSize:(CelestiaScreenshotFileType)type {
    return static_cast<BOOL>(core->saveScreenShot([filePath UTF8String], static_cast<ContentType>(type)));
}

+ (void)setUpLocale {
    CelestiaCore::initLocale();
}

+ (void)setLocaleDirectory:(NSString *)localeDirectory {
    bindtextdomain("celestia", [localeDirectory UTF8String]);
    bind_textdomain_codeset("celestia", "UTF-8");
    bindtextdomain("celestia-data", [localeDirectory UTF8String]);
    bind_textdomain_codeset("celestia-data", "UTF-8");
    bindtextdomain("celestia_ui", [localeDirectory UTF8String]);
    bind_textdomain_codeset("celestia_ui", "UTF-8");
    textdomain("celestia");

    UErrorCode status = U_ZERO_ERROR;
    NSString *language = [self language];
    NSString *uloc = [language copy];
    BOOL shouldAppendCountryCode = NO;
    if ([uloc isEqualToString:@"zh_CN"]) {
        uloc = @"zh_Hans";
        shouldAppendCountryCode = YES;
    } else if ([uloc isEqualToString:@"zh_TW"]) {
        uloc = @"zh_Hant";
        shouldAppendCountryCode = YES;
    } else {
        shouldAppendCountryCode = ![uloc containsString:@"_"];
    }
    if (shouldAppendCountryCode) {
        NSLocale *locale = [NSLocale currentLocale];
        NSString *countryCode;
        if (@available(iOS 17, macOS 14, visionOS 1, *)) {
            countryCode = [locale regionCode];
        } else {
            countryCode = [locale countryCode];
        }
        if (countryCode != nil) {
            NSString *fullLocale = [NSString stringWithFormat:@"%@_%@", uloc, countryCode];
            uloc_setDefault([fullLocale UTF8String], &status);
        } else {
            uloc_setDefault([language UTF8String], &status);
        }
    } else {
        uloc_setDefault([language UTF8String], &status);
    }
}

+ (NSString *)language {
    const char *orig = N_("LANGUAGE");
    const char *lang = _(orig);
    return lang == orig ? @"en" : [NSString stringWithUTF8String:lang];
}

- (void)runDemo {
    const auto& demoScriptFile = core->getConfig()->paths.demoScriptFile;
    if (!demoScriptFile.empty()) {
        core->cancelScript();
        core->runScript(demoScriptFile);
    }
}

// MARK: Simulation
- (CelestiaSimulation *)simulation {
    if (!_simulation) {
        _simulation = [[CelestiaSimulation alloc] initWithSimulation:core->getSimulation()];
    }
    return _simulation;
}

// MARK: History
- (void)forward {
    std::vector<Url>::size_type historySize = core->getHistory().size();
    if (historySize < 2) return;
    if (core->getHistoryCurrent() > historySize-2) return;
    core->forward();
}

- (void)back {
    core->back();
}

- (CelestiaAppState *)state {
    return [[CelestiaAppState alloc] initWithCore:core];
}

- (void)dealloc {
    core->setAlerter(nullptr);
    core->setCursorHandler(nullptr);
    core->setContextMenuHandler(nullptr);
    core->setScriptSystemAccessHandler(std::nullopt);
    delete core;
}

- (void)setHudMessagesEnabled:(BOOL)enabled {
    core->enableHudMessages(static_cast<bool>(enabled));
}

- (void)enableSelectionPointer {
    core->getRenderer()->enableSelectionPointer();
}

- (void)disableSelectionPointer {
    core->getRenderer()->disableSelectionPointer();
}

- (void)setHudOverlayImageEnabled:(BOOL)enabled {
    core->enableHudOverlayImage(static_cast<bool>(enabled));
}

- (NSString *)currentMessageText {
    auto message = core->messageText();
    if (message.empty())
        return @"";
    return [NSString stringWithUTF8String:message.data()];
}

- (void)setCustomPerspectiveProjectionLeft:(float)left right:(float)right top:(float)top bottom:(float)bottom nearZ:(float)nearZ farZ:(float)farZ {
    auto [width, height] = core->getWindowDimension();
    core->getRenderer()->setProjectionMode(std::make_shared<CustomPerspectiveProjectionMode>(left, right, top, bottom, nearZ, farZ, static_cast<float>(width), static_cast<float>(height)));
}

- (void)setCameraTransform:(simd_float4x4)cameraTransform {
    Eigen::Matrix3d m;
    auto cols = cameraTransform.columns;
    m << cols[0][0], cols[1][0], cols[2][0],
         cols[0][1], cols[1][1], cols[2][1],
         cols[0][2], cols[1][2], cols[2][2];
    core->getRenderer()->setCameraTransform(m);
}

- (void)touchDown:(simd_float3)focus {
    core->touchDown(Eigen::Vector3f(focus[0], focus[1], focus[2]));
}

- (void)touchMove:(simd_float3)focus from:(simd_double3)from to:(simd_double3)to {
    core->touchMove(Eigen::Vector3f(focus[0], focus[1], focus[2]), Eigen::Vector3f(static_cast<float>(from[0]), static_cast<float>(from[1]), static_cast<float>(from[2])), Eigen::Vector3f(static_cast<float>(to[0]), static_cast<float>(to[1]), static_cast<float>(to[2])));
}

- (void)touchUp:(simd_float3)focus {
    core->touchUp(Eigen::Vector3f(focus[0], focus[1], focus[2]));
}

@end
