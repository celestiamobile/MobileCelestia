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
import Foundation

final class ImageCacheManager {
    static let shared: ImageCacheManager = ImageCacheManager()
    private var cacheKeyDictionary: [String: String] = [:]
    private let lock = NSLock()

    private init() {
        SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter(block: { [weak self] url in
            guard let self = self else { return url.absoluteString }
            self.lock.lock()
            let key = self.cacheKeyDictionary[url.absoluteString] ?? url.absoluteString
            self.lock.unlock()
            return key
        })
    }

    func save(url: String, id: String) {
        lock.lock()
        cacheKeyDictionary[url] = id
        lock.unlock()
    }
}
