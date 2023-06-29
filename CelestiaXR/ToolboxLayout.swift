// ToolboxLayout.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import SwiftUI

struct ToolboxLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxSize = maxSize(subviews: subviews)
        let maxSpacing = maxSpacing(subviews: subviews)
        if let proposedWidth = proposal.width {
            var columnCount = Int((proposedWidth + maxSpacing) / (maxSize.width + maxSpacing).rounded(.down))
            columnCount = max(1, columnCount)
            var rowCount = subviews.count / columnCount
            if subviews.count % columnCount != 0 {
                rowCount += 1
            }
            return CGSize(
                width: proposedWidth,
                height: CGFloat(rowCount) * (maxSize.height + maxSpacing) - maxSpacing
            )
        } else {
            // Just place on one line
            return CGSize(
                width: CGFloat(subviews.count) * (maxSize.width + maxSpacing) - maxSpacing,
                height: maxSize.height
            )
        }
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var maxSize = maxSize(subviews: subviews)
        let maxSpacing = maxSpacing(subviews: subviews)
        var columnCount: Int
        if let proposedWidth = proposal.width {
            columnCount = Int((proposedWidth + maxSpacing) / (maxSize.width + maxSpacing).rounded(.down))
            columnCount = max(1, columnCount)
            maxSize.width = max(maxSize.width, (proposedWidth + maxSpacing) / CGFloat(columnCount) - maxSpacing)
        } else {
            columnCount = subviews.count
        }
        for (index, subview) in subviews.enumerated() {
            let row = index / columnCount
            let column = index % columnCount

            let preferredSize = subview.sizeThatFits(.unspecified)

            let xOffset = CGFloat(column) * (maxSize.width + maxSpacing)
            let yOffset = CGFloat(row) * (maxSize.height + maxSpacing)

            subview.place(
                at: CGPoint(
                    x: bounds.minX + xOffset + (maxSize.width - preferredSize.width) / 2,
                    y: bounds.minY + yOffset + (maxSize.height - preferredSize.height) / 2
                ),
                proposal: ProposedViewSize(preferredSize)
            )
        }
    }

    private func maxSize(subviews: Subviews) -> CGSize {
        let subviewsSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxSize = subviewsSizes.reduce(.zero) { currentMax, subviewSize in
            return CGSize(width: max(currentMax.width, subviewSize.width), height: max(currentMax.height, subviewSize.height))
        }
        return maxSize
    }

    private func maxSpacing(subviews: Subviews) -> CGFloat {
        let horizontalSpacings = subviews.indices.map { index -> CGFloat in
            guard index < subviews.count - 1 else { return 0 }
            return subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
        }
        let verticalSpacings = subviews.indices.map { index -> CGFloat in
            guard index < subviews.count - 1 else { return 0 }
            return subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
        }
        return max(horizontalSpacings.max() ?? 0, verticalSpacings.max() ?? 0)
    }
}
