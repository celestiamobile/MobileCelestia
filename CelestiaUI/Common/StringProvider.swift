// StringProvider.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import StoreKit
import UIKit

@MainActor
public protocol StringProvider: Sendable {
    func formattedPriceLine1(for product: Product, subscription: Product.SubscriptionInfo) async -> AttributedString
    func formattedPriceLine2(for product: Product, subscription: Product.SubscriptionInfo) async -> AttributedString?
}
