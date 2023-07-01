//
// FontCollection.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaXRCore
import Foundation

extension FontCollection {
    static func fontsInDirectory(_ directoryURL: URL) -> (defaultFonts: FontCollection, otherFonts: [String: FontCollection]) {
        let defaultFonts = FontCollection(
            mainFont: Font(path: directoryURL.appending(component: "NotoSans-Regular.ttf").path(), index: 0, size: 9),
            titleFont: Font(path: directoryURL.appending(component: "NotoSans-Bold.ttf").path(), index: 0, size: 15),
            normalRenderFont: Font(path: directoryURL.appending(component: "NotoSans-Regular.ttf").path(), index: 0, size: 9),
            largeRenderFont: Font(path: directoryURL.appending(component: "NotoSans-Bold.ttf").path(), index: 0, size: 15)
        )
        let otherFonts = [
            "ar": FontCollection(
                mainFont: Font(path: directoryURL.appending(component: "NotoSansArabic-Regular.ttf").path(), index: 0, size: 9),
                titleFont: Font(path: directoryURL.appending(component: "NotoSansArabic-Bold.ttf").path(), index: 0, size: 15),
                normalRenderFont: Font(path: directoryURL.appending(component: "NotoSansArabic-Regular.ttf").path(), index: 0, size: 9),
                largeRenderFont: Font(path: directoryURL.appending(component: "NotoSansArabic-Bold.ttf").path(), index: 0, size: 15)
            ),
            "ja": FontCollection(
                mainFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 0, size: 9),
                titleFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 0, size: 15),
                normalRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 0, size: 9),
                largeRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 0, size: 15)
            ),
            "ko": FontCollection(
                mainFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 1, size: 9),
                titleFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 1, size: 15),
                normalRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 1, size: 9),
                largeRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 1, size: 15)
            ),
            "zh_CN": FontCollection(
                mainFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 2, size: 9),
                titleFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 2, size: 15),
                normalRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 2, size: 9),
                largeRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 2, size: 15)
            ),
            "zh_TW": FontCollection(
                mainFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 3, size: 9),
                titleFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 3, size: 15),
                normalRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 3, size: 9),
                largeRenderFont: Font(path: directoryURL.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 3, size: 15)
            )
        ]
        return (defaultFonts, otherFonts)
    }
}

