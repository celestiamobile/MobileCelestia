//
// ImageCacheManager.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import SDWebImage

final class ImageCacheManager {
    static let shared: ImageCacheManager = ImageCacheManager()
    private var cacheKeyDictionary: [String: String] = [:]

    private init() {
        SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter(block: { [weak self] url in
            return self?.cacheKeyDictionary[url.absoluteString] ?? url.absoluteString
        })
    }

    func save(url: String, id: String) {
        cacheKeyDictionary[url] = id
    }
}
