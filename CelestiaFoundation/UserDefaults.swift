//
// UserDefaults.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public extension UserDefaults {
    func url(for key: String, defaultValue: URL) -> UniformedURL {
        if let bookmark = self.value(forKey: key) as? Data {
            if let url = try? UniformedURL(bookmark: bookmark) {
                if url.stale {
                    do {
                        if let newBookmark = try url.bookmark() {
                            setValue(newBookmark, forKey: key)
                        }
                    } catch {}
                }
                return url
            }
            return UniformedURL(url: defaultValue)
        } else if let path = self.value(forKey: key) as? String {
            return UniformedURL(url: URL(fileURLWithPath: path))
        } else {
            return UniformedURL(url: defaultValue)
        }
    }
}
