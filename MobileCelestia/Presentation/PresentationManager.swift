//
// SlideInPresentationManager.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

final class SlideInPresentationAnimator: NSObject {
    // MARK: - Properties
    let direction: PresentationManager.PresentationDirection
    let isPresentation: Bool

    // MARK: - Initializers
    init(direction: PresentationManager.PresentationDirection, isPresentation: Bool) {
        self.direction = direction
        self.isPresentation = isPresentation
        super.init()
    }
}

extension SlideInPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from

        guard let controller = transitionContext.viewController(forKey: key)
            else { return }

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        switch direction {
        case .left:
            dismissedFrame.origin.x = -presentedFrame.width
        case .right:
            dismissedFrame.origin.x = transitionContext.containerView.frame.size.width
        case .top:
            dismissedFrame.origin.y = -presentedFrame.height
        case .bottom, .bottomLeft, .bottomRight:
            dismissedFrame.origin.y = transitionContext.containerView.frame.size.height
        }

        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame

        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        UIView.animate(withDuration: animationDuration, animations: {
            controller.view.frame = finalFrame
        }, completion: { finished in
            if !self.isPresentation {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        })
    }
}

final class SheetPresentationAnimator: NSObject {
    // MARK: - Properties
    let isPresentation: Bool

    // MARK: - Initializers
    init(isPresentation: Bool) {
        self.isPresentation = isPresentation
        super.init()
    }
}

extension SheetPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from

        guard let controller = transitionContext.viewController(forKey: key)
            else { return }

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        dismissedFrame.origin.y = transitionContext.containerView.frame.size.height

        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame

        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        UIView.animate(withDuration: animationDuration, animations: {
            controller.view.frame = finalFrame
        }, completion: { finished in
            if !self.isPresentation {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        })
    }
}

class PresentationManager: NSObject {
    enum PresentationDirection {
        case left
        case top
        case right
        case bottom
        case bottomLeft
        case bottomRight
    }

    private let direction: PresentationDirection
    private let useSheetIfPossible: Bool

    private var currentTraitCollection: UITraitCollection?

    init(direction: PresentationDirection, useSheetIfPossible: Bool = false) {
        self.direction = direction
        self.useSheetIfPossible = useSheetIfPossible
        super.init()
    }
}

extension PresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if useSheetIfPossible {
            let pc = SheetPresentationController(presentedViewController: presented, presenting: presenting)
            if #available(iOS 13.0, *) {
                pc.overrideTraitCollection = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceLevel: .base), UITraitCollection(horizontalSizeClass: .compact)])
            }
            pc.delegate = self
            return pc
        }
        let pc = SlideInPresentationController(presentedViewController: presented, presenting: presenting, direction: direction)
        pc.delegate = self
        return pc
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if useSheetIfPossible {
            return SheetPresentationAnimator(isPresentation: true)
        }
        return SlideInPresentationAnimator(direction: direction, isPresentation: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if useSheetIfPossible {
            return SheetPresentationAnimator(isPresentation: false)
        }
        return SlideInPresentationAnimator(direction: direction, isPresentation: false)
    }
}

extension PresentationManager: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
