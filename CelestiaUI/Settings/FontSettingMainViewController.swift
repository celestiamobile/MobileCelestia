// FontSettingMainViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

public struct FontSettingContext {
    let normalFontPathKey: String
    let normalFontIndexKey: String
    let boldFontPathKey: String
    let boldFontIndexKey: String

    public init(normalFontPathKey: String, normalFontIndexKey: String, boldFontPathKey: String, boldFontIndexKey: String) {
        self.normalFontPathKey = normalFontPathKey
        self.normalFontIndexKey = normalFontIndexKey
        self.boldFontPathKey = boldFontPathKey
        self.boldFontIndexKey = boldFontIndexKey
    }
}

@available(iOS 15, *)
final class FontSettingMainViewController: SubscriptionBackingViewController {
    init(context: FontSettingContext, userDefaults: UserDefaults, subscriptionManager: SubscriptionManager, openSubscriptionManagement: @escaping () -> Void) {
        super.init(
            subscriptionManager: subscriptionManager,
            openSubscriptionManagement: openSubscriptionManagement,
            viewControllerBuilder: { _ in
                let fonts = await Task(priority: .background) {
                    return readSystemFonts()
                }.value
                return FontSettingViewController(
                    userDefaults: userDefaults,
                    normalFontPathKey: context.normalFontPathKey,
                    normalFontIndexKey: context.normalFontIndexKey,
                    boldFontPathKey: context.boldFontPathKey,
                    boldFontIndexKey: context.boldFontIndexKey,
                    customFonts: fonts
                )
            }
        )
        title = CelestiaString("Font", comment: "")
        windowTitle = title
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func readSystemFonts() -> [DisplayFont] {
    let allFonts = CTFontCollectionCreateFromAvailableFonts(nil)
    guard let fontDescriptors = CTFontCollectionCreateMatchingFontDescriptors(allFonts) as? [CTFontDescriptor] else {
        return []
    }
    var fontPaths = Set<String>()
    for fontDescriptor in fontDescriptors {
        if let url = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontURLAttribute) as? URL, url.isFileURL  {
            fontPaths.insert(url.path)
        }
    }
    var fontCollections = fontPaths.compactMap { path -> Font? in
        let font = Font(path: path)
        if font.fontNames.isEmpty { return nil }
        return font
    }
    fontCollections.sort { lhs, rhs in
        lhs.fontNames[0] < rhs.fontNames[0]
    }
    var fonts = [DisplayFont]()
    for fontCollection in fontCollections {
        for (index, fontName) in fontCollection.fontNames.enumerated() {
            fonts.append(DisplayFont(font: CustomFont(path: fontCollection.path, ttcIndex: index), name: fontName))
        }
    }
    return fonts
}
