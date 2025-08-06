// Formatter.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation

public extension NumberFormatter {
    func string(from value: Int) -> String {
        self.string(from: NSNumber(value: value)) ?? String.localizedStringWithFormat("%d", value)
    }

    func string(from value: Double) -> String {
        self.string(from: NSNumber(value: value)) ?? String.localizedStringWithFormat("%.\(maximumFractionDigits)f", value)
    }

    func string(from value: Float) -> String {
        self.string(from: NSNumber(value: value)) ?? String.localizedStringWithFormat("%.\(maximumFractionDigits)f", value)
    }
}
