//
// BodyInfoLayoutDelegate.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

fileprivate enum Constants {
    static let buttonSpacing: CGFloat = GlobalConstants.pageMediumGapHorizontal
}

extension InfoViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 2 * GlobalConstants.pageMediumMarginHorizontal
        let height = collectionView.bounds.height
        if indexPath.section == 0 { return CGSize(width: width.rounded(.towardZero), height: height) }
        return CGSize(width: ((width - Constants.buttonSpacing) / 2).rounded(.towardZero), height: 1)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return GlobalConstants.pageMediumGapVertical
        }
        return Constants.buttonSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return GlobalConstants.pageMediumGapHorizontal
        }
        return Constants.buttonSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let horizontal = GlobalConstants.pageMediumMarginHorizontal
        if section == 0 {
            return UIEdgeInsets(top: GlobalConstants.pageMediumMarginVertical, left: horizontal, bottom: GlobalConstants.pageMediumGapVertical, right: horizontal)
        }
        return UIEdgeInsets(top: 0, left: horizontal, bottom: GlobalConstants.pageMediumMarginVertical, right: horizontal)
    }
}