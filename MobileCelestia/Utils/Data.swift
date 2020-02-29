//
//  Data.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/29.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

extension Data {
    func base64EncodedURLString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64EncodedURL: String) {
        var base64 = base64EncodedURL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        self.init(base64Encoded: base64)
    }
}
