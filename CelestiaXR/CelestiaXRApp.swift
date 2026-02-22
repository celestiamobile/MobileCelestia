// CelestiaXRApp.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import CelestiaXRCore
import CompositorServices
import Observation
import SwiftUI

enum LayoutConstants {
    static let largeVerticalSpacing: CGFloat = 24
    static let mediumVerticalSpacing: CGFloat = 16
    static let smallVerticalSpacing: CGFloat = 8
}

struct MetalLayerConfiguration: CompositorLayerConfiguration {
    let foveatedRendering: Bool

    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        configuration.layout = .dedicated
        configuration.isFoveationEnabled = foveatedRendering && capabilities.supportsFoveation
        configuration.colorFormat = .rgba8Unorm_srgb
    }
}

struct CelestiaAssetProvider: AssetProvider {
    func image(for image: AssetImage) -> UIImage {
        return UIImage(resource: imageResource(for: image))
    }

    private func imageResource(for image: AssetImage) -> ImageResource {
        switch image {
        case .loadingIcon:
            .loadingIcon
        case .browserTabDso:
            if #available(iOS 26, *) {
                .symbolGalaxy
            } else {
                .browserTabDso
            }
        case .browserTabSso:
            if #available(iOS 26, *) {
                .symbolSun
            } else {
                .browserTabSso
            }
        case .browserTabStar:
            if #available(iOS 26, *) {
                .symbolStar
            } else {
                .browserTabStar
            }
        case .tutorialSwitchMode:
            .tutorialSwitchMode
        }
    }
}

@Observable class URLManager {
    var savedURL: AppURL?
}

@main
struct CelestiaXRApp: App {
    private enum Constants {
        static let windowSize = CGSize(width: 700, height: 800)
    }

    @Environment(\.openWindow) private var openWindow
    @State var immersionStyle: (any ImmersionStyle)

    private let bundle: Bundle
    private let defaultDataDirectoryURL: URL
    private let defaultConfigFileURL: URL
    private let userDefaults: UserDefaults
    private let browserItemStore = BrowserItemStore()
    private let renderer: XRRenderer
    private let interactionManager: InteractionManager
    private let userDirectory: URL
    private let resourceManager: ResourceManager
    private let windowManager = WindowManager()
    private let urlManager = URLManager()
    private let foveatedRendering: Bool
    private let requestHandler = RequestHandlerImpl()
    private let assetProvider = CelestiaAssetProvider()

    init() {
        let useMixedImmersionDefaultValue = false
        self.immersionStyle = .full
        AppCore.setUpLocale()
        let userDirectory = URL.documentsDirectory.appending(component: "CelestiaResources")
        let bundle = Bundle.app
        let defaults = UserDefaults.standard
        let defaultDataDirectoryURL = bundle.url(forResource: "CelestiaResources", withExtension: nil)!
        let defaultConfigFileURL = defaultDataDirectoryURL.appending(component: "celestia.cfg")
        userDefaults = defaults
        let extraDirectoryURL = userDirectory.appending(component: "extras")
        let extraScriptURL = userDirectory.appending(component: "scripts")
        let renderer = {
            let defaultConfigPlistPath = bundle.path(forResource: "defaults", ofType: "plist")
            let fontDirectoryURL = bundle.url(forResource: "Fonts", withExtension: nil)!
            let (defaultFonts, otherFonts) = FontCollection.fontsInDirectory(fontDirectoryURL)
            return XRRenderer(
                renderer: Renderer(
                    resourceFolderPath: defaultDataDirectoryURL.path(percentEncoded: false),
                    configFilePath: defaultConfigFileURL.path(percentEncoded: false),
                    extraDirectories: [extraDirectoryURL.path(percentEncoded: false)],
                    userDefaults: defaults,
                    appDefaultsPath:defaultConfigPlistPath,
                    defaultFonts: defaultFonts,
                    otherFonts: otherFonts,
                    antiAliasing: defaults[.msaa] == true,
                    useMixedImmersion: useMixedImmersionDefaultValue
                )
            )
        }()
        CelestiaActor.underlyingExecutor = renderer
        self.renderer = renderer
        self.bundle = bundle
        self.defaultDataDirectoryURL = defaultDataDirectoryURL
        self.defaultConfigFileURL = defaultConfigFileURL
        self.userDirectory = userDirectory
        self.resourceManager = ResourceManager(extraAddonDirectory: extraDirectoryURL, extraScriptDirectory: extraScriptURL)
        let interactionManager = InteractionManager()
        interactionManager.gameControllerManager = GameControllerManager(
            executor: renderer,
            canAcceptEvents: { return renderer.rendererStatus == .rendering },
            actionRemapper: { button in
                guard let remapped: Int = defaults[button.userDefaultsKey] else { return nil }
                return GameControllerAction(rawValue: remapped)
            },
            thumbstickStatus: { thumbstick in
                switch thumbstick {
                case .left:
                    return defaults[.gameControllerLeftThumbstickEnabled] != false
                case .right:
                    return defaults[.gameControllerRightThumbstickEnabled] != false
                }
            },
            axisInversion: { axis in
                switch axis {
                case .X:
                    return defaults[.gameControllerInvertX] == true
                case .Y:
                    return defaults[.gameControllerInvertY] == true
                }
            },
            connectedGameControllerChanged: { [weak interactionManager] controller in
                guard let interactionManager else { return }
                interactionManager.connectedGameController = controller
            }
        )
        self.interactionManager = interactionManager
        self.foveatedRendering = defaults[.foveatedRendering] == true
        self.renderer.prepare()
    }

    var body: some Scene {
        WindowGroup(id: "StartUp") {
            StartUpView(immersionStyle: $immersionStyle)
                .onAppear(perform: {
                    windowManager.isStartUpWindowVisible = true
                })
                .onDisappear(perform: {
                    windowManager.isStartUpWindowVisible = false
                })
                .environment(renderer)
                .environment(interactionManager)
                .environment(windowManager)
                .onOpenURL { url in
                    if let appURL = AppURL.from(url: url, openInPlace: url.isFileURL) {
                        urlManager.savedURL = appURL
                    }
                }
                .onContinueUserActivity("space.celestia.celestia.addon-user-activity") { userActivity in
                    if let appURL = AppURL.from(userActivity: userActivity) {
                        urlManager.savedURL = appURL
                    }
                }
        }
        .defaultSize(CGSize(width: 640, height: 1000))
        .onChange(of: renderer.rendererStatus) { _, newValue in
            if newValue == .invalidated, !windowManager.isStartUpWindowVisible {
                openWindow(id: "StartUp")
            } else if newValue == .rendering {
                let onboardMessageDisplayed = userDefaults[.onboardMessageDisplayed] ?? false
                if !onboardMessageDisplayed, !windowManager.isToolWindowVisible {
                    userDefaults[.onboardMessageDisplayed] = true
                    windowManager.tool = .help
                    openWindow(id: "Tool")
                }

                if let url = urlManager.savedURL {
                    handleURL(url)
                } else {
                    Task {
                        do {
                            let lastNews = try await requestHandler.getLatestMetadata(language: AppCore.language)
                            if userDefaults[.lastNewsID] != lastNews.id {
                                openWindow(id: "LastGuideWindow", value: lastNews.id)
                            }
                        } catch {}
                    }
                }

                if let alertMessage = renderer.alertMessage {
                    openWindow(id: "AlertWindow", value: AlertContent.information(text: alertMessage))
                    renderer.alertMessage = nil
                }

                if renderer.systemAccessRequest != nil {
                    openWindow(id: "SystemAccessRequestWindow")
                }
            }
        }
        .onChange(of: urlManager.savedURL) { _, newValue in
            guard let newValue else { return }
            guard renderer.rendererStatus == .rendering else { return }

            handleURL(newValue)
        }
        .onChange(of: renderer.alertMessage) { _, newValue in
            guard let newValue else { return }
            guard renderer.rendererStatus == .rendering else { return }

            openWindow(id: "AlertWindow", value: AlertContent.information(text: newValue))
            renderer.alertMessage = nil
        }
        .onChange(of: renderer.systemAccessRequest) { _, newValue in
            guard newValue != nil else { return }
            guard renderer.rendererStatus == .rendering else { return }

            openWindow(id: "SystemAccessRequestWindow")
        }
        .handlesExternalEvents(matching: ["celguide", "celaddon", "http", "https", "celestia"])

        WindowGroup(id: "Tool") {
            ToolView(userDefault: userDefaults, bundle: bundle, defaultDataDirectory: defaultDataDirectoryURL, defaultConfigFile: defaultConfigFileURL, userDirectory: userDirectory, resourceManager: resourceManager, requestHandler: requestHandler, assetProvider: assetProvider)
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
                .environment(browserItemStore)
                .environment(windowManager)
                .onAppear(perform: {
                    windowManager.isToolWindowVisible = true
                })
                .onDisappear(perform: {
                    windowManager.isToolWindowVisible = false
                })
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "SubsystemWindow", for: UUID.self) { $id in
            SubsystemBrowserWindow(id: id ?? UUID())
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
                .environment(browserItemStore)
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "AddonWindow", for: String.self) { $id in
            AddonWindow(id: id ?? "", resourceManager: resourceManager, requestHandler: requestHandler)
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "AddonCategoryWindow", for: CategoryInfo.self) { $id in
            AddonCategoriesView(resourceManager: resourceManager, requestHandler: requestHandler, category: id)
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "ObjectInfoWindow", for: String.self) { $path in
            ObjectInfoWindow(objectPath: path ?? "")
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
                .environment(browserItemStore)
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "GuideWindow", for: String.self) { $id in
            GuideView(id: id ?? "", resourceManager: resourceManager, requestHandler: requestHandler, actionHandler: nil)
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "LastGuideWindow", for: String.self) { $id in
            GuideView(id: id ?? "", resourceManager: resourceManager, requestHandler: requestHandler, actionHandler: { action in
                switch action {
                case let .ack(id):
                    userDefaults[.lastNewsID] = id
                default:
                    break
                }
            })
            .disabled(renderer.rendererStatus != .rendering)
            .environment(renderer)
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "InfoWindow") {
            InfoWindow()
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
                .environment(browserItemStore)
                .onAppear(perform: {
                    windowManager.isInfoWindowVisible = true
                })
                .onDisappear(perform: {
                    windowManager.isInfoWindowVisible = false
                })
        }
        .defaultSize(Constants.windowSize)
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "AlertWindow", for: AlertContent.self) { $content in
            AlertWindow(content: content)
                .disabled(renderer.rendererStatus != .rendering)
                .environment(renderer)
        }
        .defaultSize(CGSize(width: 1, height: 1))
        .handlesExternalEvents(matching: [])

        WindowGroup(id: "SystemAccessRequestWindow") {
            SystemAccessRequestWindow { granted in
                guard let request = renderer.systemAccessRequest else { return }
                renderer.systemAccessRequest = nil
                request.granted = granted
                request.dispatchGroup.leave()
            }
        }
        .defaultSize(CGSize(width: 1, height: 1))
        .handlesExternalEvents(matching: [])

        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: MetalLayerConfiguration(foveatedRendering: foveatedRendering)) { layerRenderer in
                renderer.startRendering(with: layerRenderer)
                layerRenderer.onSpatialEvent = { collection in
                    renderer.enqueue(events: collection)
                }
            }
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed, .full)
        .handlesExternalEvents(matching: [])
    }

    private func handleURL(_ appURL: AppURL) {
        switch appURL {
        case .celScript(let url):
            openWindow(id: "AlertWindow", value: AlertContent.celScript(url: url))
        case .celURL(let url):
            openWindow(id: "AlertWindow", value: AlertContent.celURL(url: url))
        case .windowURL(let url, _):
            switch url {
            case .addon(let id):
                openWindow(id: "AddonWindow", value: id)
            case .guide(let id):
                openWindow(id: "GuideWindow", value: id)
            case let .object(path, action):
                Task {
                    let selection: Selection? = await Task { @CelestiaActor in
                        let core = CelestiaActor.appCore
                        let selection = core.simulation.findObject(from: path)
                        guard !selection.isEmpty else { return nil }

                        if let action {
                            let objectAction = ObjectAction(action)
                            switch objectAction {
                            case .select:
                                core.simulation.selection = selection
                            case let .wrapped(action):
                                core.simulation.selection = selection
                                core.receive(action)
                            default:
                                break
                            }

                            // Already handled
                            return nil
                        }

                        return selection
                    }.value

                    guard selection != nil else { return }
                    openWindow(id: "ObjectInfoWindow", value: path)
                }
            }
        }
        urlManager.savedURL = nil
    }
}
