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

extension InfoViewController: UICollectionViewDelegateFlowLayout {
    private var buttonSpacing: CGFloat { return 16 }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 2 * buttonSpacing
        let height = collectionView.bounds.height
        if indexPath.section == 0 { return CGSize(width: width.rounded(.towardZero), height: height) }
        return CGSize(width: ((width - buttonSpacing) / 2).rounded(.towardZero), height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return buttonSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return buttonSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 { return UIEdgeInsets(top: buttonSpacing, left: buttonSpacing, bottom: 0, right: buttonSpacing) }
        return UIEdgeInsets(top: buttonSpacing, left: buttonSpacing, bottom: buttonSpacing, right: buttonSpacing)
    }
}
