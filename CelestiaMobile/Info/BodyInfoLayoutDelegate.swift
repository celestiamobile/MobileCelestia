//
//  BodyInfoLayoutDelegate.swift
//  TestViewController
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 Li Linfeng. All rights reserved.
//

import UIKit

extension InfoViewController: UICollectionViewDelegateFlowLayout {
    private var buttonSpacing: CGFloat { return 16 }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 2 * buttonSpacing
        let height = collectionView.bounds.height
        if indexPath.section == 0 { return CGSize(width: width.rounded(.towardZero), height: height) }
        return CGSize(width: ((width - buttonSpacing) / 2).rounded(.towardZero), height: height)
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
